# MetabookSDK — build, test, and the release pipeline.
# Run `make help` for the list of targets.

.DEFAULT_GOAL := help
SHELL         := /bin/bash

DIST_DIR      ?= dist
IOS_SIM       ?= platform=iOS Simulator,name=iPhone 17

.PHONY: help build test lint format ios clean

help: ## Show this help message.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# ── Build & test ──────────────────────────────────────────────────────────────

build: ## Build the package (debug).
	@swift build

test: ## Run the test suite and keep the results bundle for CI.
	@swift test --parallel --xunit-output .build/test-results/results.xml

lint: ## Lint with swift-format (.swift-format at the root).
	@swift format lint --strict --recursive Sources Tests Package.swift

format: ## Rewrite sources with swift-format.
	@swift format --in-place --recursive Sources Tests Package.swift

ios: ## Compile the library for the iOS Simulator (needs the iOS platform installed).
	@xcodebuild -scheme MetabookSDK -destination '$(IOS_SIM)' -quiet build

clean: ## Remove build products.
	@rm -rf .build $(DIST_DIR)

# ── Release pipeline ──────────────────────────────────────────────────────────
# The branch model lives in .github/WORKFLOW.md. Every CI step is one target
# here, so anything the pipeline does can be reproduced locally.

# The long-lived branch. Production; protected; PRs only, from release/vX.Y.Z.
TRUNK              ?= main

# Bump used when opening the next release branch.
BUMP               ?= minor

# Line-count thresholds for promote: insertions+deletions of next...dev.
# < CHURN_MINOR → patch (0.0.+1); < CHURN_MAJOR → minor (0.+1.0); else major.
CHURN_MINOR        ?= 100
CHURN_MAJOR        ?= 1000

# Commit range for `release-notes`.
RANGE              ?= origin/$(TRUNK)..HEAD

# owner/name. The workflows set this from ${{ github.repository }}; otherwise
# it is derived from the origin remote. `gh` reads this variable natively too.
# (sed uses `,` as its delimiter: a `#` would open a comment, even in $(shell).)
GH_REPO            ?= $(shell git config --get remote.origin.url 2>/dev/null | sed -E 's,.*github\.com[:/],,; s,\.git$$,,')

# Branch and PR-title types accepted by `pr-guard`.
TYPES              := feat|fix|chore|docs|ci|refactor|test|perf|build|style|revert

# The released version lives in VERSION (one line) and is mirrored into
# Sources/MetabookSDK/MetabookSDKInfo.swift so consumers can read it at runtime.
pkg_version         = tr -d '[:space:]' < VERSION

.PHONY: pkg-version next-version version-set release-notes pr-guard ci pack \
        release-pr release-branch delete-branch tag-release \
        rulesets-diff rulesets-apply \
        churn-info churn-bump bootstrap-lanes promote-pr cut-release version-check \
        sync-lanes cleanup-cycle cleanup-local spi-url spi-check


# --- build & package --------------------------------------------------------

pkg-version: ## Print the version in VERSION.
	@echo "$$($(pkg_version))"

version-set: ## Write VERSION into VERSION and MetabookSDKInfo.swift (env: VERSION).
	@set -eu; : "$${VERSION:?VERSION is required}"; \
	printf '%s\n' "$$VERSION" > VERSION; \
	sed "s/static let version = \".*\"/static let version = \"$$VERSION\"/" \
	  Sources/MetabookSDK/MetabookSDKInfo.swift > Sources/MetabookSDK/MetabookSDKInfo.swift.tmp; \
	mv Sources/MetabookSDK/MetabookSDKInfo.swift.tmp Sources/MetabookSDK/MetabookSDKInfo.swift; \
	echo "  VERSION is now $$VERSION"

version-check: ## Fail if VERSION and MetabookSDKInfo.swift disagree.
	@set -eu; v="$$($(pkg_version))"; \
	grep -q "static let version = \"$$v\"" Sources/MetabookSDK/MetabookSDKInfo.swift \
	  || { echo "::error::MetabookSDKInfo.swift does not carry version $$v"; exit 1; }; \
	echo "version $$v is consistent"

ci: lint version-check build test ios ## Everything CI runs on a pull request.

pack: ## Build the publishable source archive (the artifact CI uploads and attaches to the release).
	@set -eu; rm -rf $(DIST_DIR); mkdir -p $(DIST_DIR); \
	v="$$($(pkg_version))"; \
	swift build -c release; \
	swift package archive-source --output "$(DIST_DIR)/MetabookSDK-$$v.zip"; \
	(cd $(DIST_DIR) && shasum -a 256 "MetabookSDK-$$v.zip" > "MetabookSDK-$$v.zip.sha256"); \
	ls -lh $(DIST_DIR)

# --- Swift Package Index ----------------------------------------------------

# Listing is a one-time PR to SwiftPackageIndex/PackageList, opened for you by
# the OAuth flow at https://swiftpackageindex.com/add-a-package. Every later
# tag is ingested automatically. `spi-check` is the preflight for that one
# submission and a regression guard afterwards: it asserts each requirement
# from the add-a-package page plus the .spi.yml schema SPI's builder enforces.
SPI_PACKAGE_LIST ?= https://raw.githubusercontent.com/SwiftPackageIndex/PackageList/main/packages.json
SPI_PLATFORMS    := android ios linux macos-spm macos-xcodebuild tvos visionos watchos wasm
# SPIManifest's SwiftVersion enum — the toolchains SPI's builder actually has.
SPI_SWIFT        := 6.1 6.2 6.3 6.4
SPI_MANIFEST_MAX := 1500

# The URL SPI wants: canonical owner/repo casing, https, and a .git suffix.
spi_url = slug="$$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"; \
          [ -n "$$slug" ] || slug="$$(git remote get-url origin \
            | sed -E 's,^(https://github\.com/|git@github\.com:),,; s,\.git$$,,')"; \
          url="https://github.com/$$slug.git"

spi-url: ## Print the canonical package URL to submit to the Swift Package Index.
	@set -eu; $(spi_url); echo "$$url"

spi-check: ## Check every Swift Package Index listing requirement (run before submitting).
	@set -eu; $(spi_url); fail=0; \
	ok()   { printf '  \033[32m✓\033[0m %s\n' "$$1"; }; \
	bad()  { printf '  \033[31m✗\033[0m %s\n' "$$1"; fail=1; }; \
	echo "Swift Package Index preflight for $$url"; echo; \
	\
	vis="$$(gh repo view --json visibility -q .visibility 2>/dev/null || echo UNKNOWN)"; \
	[ "$$vis" = "PUBLIC" ] && ok "repository is public" \
	  || bad "repository visibility is $$vis (SPI needs PUBLIC)"; \
	\
	case "$$url" in \
	  https://github.com/*.git) ok "URL has the https protocol and the .git extension" ;; \
	  *) bad "URL must be https://…​.git, got $$url" ;; \
	esac; \
	\
	[ -f Package.swift ] && ok "Package.swift is in the root folder" \
	  || bad "no Package.swift in the root folder"; \
	\
	tools="$$(sed -n 's|^// *swift-tools-version: *\([0-9.]*\).*|\1|p' Package.swift | head -1)"; \
	case "$$tools" in \
	  "") bad "cannot read swift-tools-version from Package.swift" ;; \
	  [0-4].*) bad "swift-tools-version $$tools is below the required 5.0" ;; \
	  *) ok "swift-tools-version $$tools is 5.0 or later" ;; \
	esac; \
	newest="$$(for v in $(SPI_SWIFT); do echo "$$v"; done | sort -V | tail -1)"; \
	if [ -n "$$tools" ] && [ "$$(printf '%s\n%s\n' "$$tools" "$$newest" | sort -V | tail -1)" != "$$newest" ]; then \
	  bad "swift-tools-version $$tools is newer than SPI's newest builder toolchain ($$newest) — the manifest will not parse on their side"; \
	else \
	  older="$$(for v in $(SPI_SWIFT); do \
	    [ "$$(printf '%s\n%s\n' "$$v" "$$tools" | sort -V | head -1)" = "$$v" ] && [ "$$v" != "$$tools" ] && echo "$$v"; \
	  done | tr '\n' ' ')"; \
	  ok "SPI builds on Swift $(SPI_SWIFT)$${older:+ (rows for $${older%% } will be red: older than $$tools)}"; \
	fi; \
	\
	if swift package dump-package > /tmp/spi-dump.$$$$.json 2>/tmp/spi-dump.$$$$.err; then \
	  ok "swift package dump-package emits valid JSON"; \
	else \
	  bad "swift package dump-package failed:"; sed 's/^/      /' /tmp/spi-dump.$$$$.err; \
	fi; \
	\
	git fetch --quiet --tags origin 2>/dev/null || true; \
	tag="$$(git tag -l 'v[0-9]*.[0-9]*.[0-9]*' | sort -V | tail -1)"; \
	if [ -n "$$tag" ]; then ok "semantic version tag present ($$tag)"; \
	else bad "no vX.Y.Z tag yet — merge the release PR so release.yml tags v$$($(pkg_version))"; fi; \
	\
	if swift build > /tmp/spi-build.$$$$.log 2>&1; then \
	  ok "the package compiles (macOS; 'make ci' also covers the iOS Simulator)"; \
	else \
	  bad "swift build failed:"; tail -20 /tmp/spi-build.$$$$.log | sed 's/^/      /'; \
	fi; \
	\
	if [ -f .spi.yml ]; then \
	  size="$$(wc -c < .spi.yml | tr -d ' ')"; \
	  [ "$$size" -le $(SPI_MANIFEST_MAX) ] \
	    && ok ".spi.yml is $$size bytes (SPI reads at most $(SPI_MANIFEST_MAX))" \
	    || bad ".spi.yml is $$size bytes — SPI ignores anything over $(SPI_MANIFEST_MAX)"; \
	  for p in $$(sed -n 's/.*platform:[[:space:]]*\([a-zA-Z-]*\).*/\1/p' .spi.yml); do \
	    n="$$(echo "$$p" | tr 'A-Z' 'a-z')"; \
	    case "$$n" in macos|macosspm) n=macos-spm ;; macosxcodebuild) n=macos-xcodebuild ;; esac; \
	    case " $(SPI_PLATFORMS) " in \
	      *" $$n "*) ok ".spi.yml platform '$$p' is a builder platform" ;; \
	      *) bad ".spi.yml platform '$$p' is not one of: $(SPI_PLATFORMS)" ;; \
	    esac; \
	  done; \
	  for t in $$(sed -n 's/.*documentation_targets:[[:space:]]*\[\(.*\)\].*/\1/p' .spi.yml | tr -d ' ' | tr ',' ' '); do \
	    if jq -e --arg t "$$t" '.targets[] | select(.name == $$t)' /tmp/spi-dump.$$$$.json >/dev/null 2>&1; then \
	      ok ".spi.yml documents target '$$t', which exists"; \
	    else \
	      bad ".spi.yml documents target '$$t', which Package.swift does not declare"; \
	    fi; \
	  done; \
	else \
	  ok "no .spi.yml (optional — only needed for hosted DocC)"; \
	fi; \
	\
	if grep -qF "$$url" README.md; then ok "README.md advertises the canonical URL"; \
	else bad "README.md does not mention $$url (check the owner/repo casing)"; fi; \
	\
	if curl -fsSL $(SPI_PACKAGE_LIST) | grep -qiF "$$url"; then \
	  echo; echo "Already listed: https://swiftpackageindex.com/$${url#https://github.com/}"; \
	else \
	  echo; echo "Not listed yet. Submit $$url once at https://swiftpackageindex.com/add-a-package"; \
	fi; \
	rm -f /tmp/spi-dump.$$$$.json /tmp/spi-dump.$$$$.err /tmp/spi-build.$$$$.log; \
	echo; \
	[ "$$fail" -eq 0 ] && echo "All Swift Package Index requirements met." \
	  || { echo "::error::the package is not ready for the Swift Package Index"; exit 1; }

cut-release: ## Cut or refresh release/v<VERSION> from origin/next (env: VERSION).
	@set -eu; \
	git fetch --quiet --force origin \
	  "+refs/heads/next:refs/remotes/origin/next" \
	  "+refs/heads/$(TRUNK):refs/remotes/origin/$(TRUNK)"; \
	if git diff --quiet origin/$(TRUNK) origin/next; then \
	  echo "next and $(TRUNK) have the same tree — nothing to cut"; \
	  exit 0; \
	fi; \
	existing="$$(gh pr list --base $(TRUNK) --state open --json headRefName \
	  --jq '[.[] | select(.headRefName | test("^release/v[0-9]"))] | .[0].headRefName // empty')"; \
	if [ -n "$$existing" ]; then \
	  version="$${existing#release/v}"; \
	  echo "in-flight $$existing — refreshing at v$$version"; \
	else \
	  if [ -z "$${VERSION-}" ]; then \
	    body="$$(gh pr list --base next --head dev --state merged --limit 1 \
	      --json body --jq '.[0].body // empty')"; \
	    VERSION="$$(printf '%s' "$$body" | sed -n 's/.*<!-- release: v\([0-9][0-9.]*\) -->.*/\1/p')"; \
	  fi; \
	  if [ -z "$${VERSION-}" ]; then \
	    b="$$($(MAKE) -s --no-print-directory churn-bump FROM=origin/$(TRUNK) TO=origin/next)"; \
	    VERSION="$$($(MAKE) -s --no-print-directory next-version BUMP="$$b")"; \
	  fi; \
	  version="$$VERSION"; \
	fi; \
	: "$${version:?could not determine VERSION to cut}"; \
	branch="release/v$$version"; \
	if git fetch --quiet origin "+refs/heads/$$branch:refs/remotes/origin/$$branch" 2>/dev/null; then \
	  git checkout --quiet -B "$$branch" "origin/$$branch"; \
	  git merge --quiet --no-edit -X theirs origin/next; \
	else \
	  git checkout --quiet -B "$$branch" origin/next; \
	fi; \
	$(MAKE) -s --no-print-directory version-set VERSION="$$version"; \
	git add VERSION Sources/MetabookSDK/MetabookSDKInfo.swift; \
	if git diff --cached --quiet; then \
	  echo "VERSION already $$version"; \
	else \
	  git commit --quiet -m "chore(release): open v$$version"; \
	fi; \
	git push --quiet -u origin "$$branch"; \
	echo "updated $$branch"

# --- versions ---------------------------------------------------------------

next-version: ## Print the version after the newest vX.Y.Z tag, or after VERSION if untagged (BUMP=major|minor|patch).
	@{ git tag -l 'v[0-9]*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$$' | sed 's/^v//'; } \
	  | sort -t. -k1,1n -k2,2n -k3,3n | tail -1 \
	  | { read -r cur || cur="$$($(pkg_version))"; printf '%s\n' "$${cur:-0.0.0}"; } \
	  | awk -F. -v b='$(BUMP)' \
	      '{ maj = $$1; min = $$2; pat = $$3 } \
	       END { if (b == "major") printf "%d.0.0\n", maj + 1; \
	             else if (b == "patch") printf "%d.%d.%d\n", maj, min, pat + 1; \
	             else printf "%d.%d.0\n", maj, min + 1 }'

# Writes a temp file and moves it rather than using `sed -i`: the in-place flag
# takes a mandatory argument on BSD sed (macOS) and must not have one on GNU
# sed (CI), so no single invocation works in both places.
release-notes: ## Print a markdown changelog for RANGE (default origin/$(TRUNK)..HEAD).
	@git log --no-merges --reverse --pretty='- %s' $(RANGE) | grep . \
	  || echo '- _Nothing merged yet._'

# --- pull requests ----------------------------------------------------------

# Dependabot opens `dependabot/<ecosystem>/<dep>-<version>` with a "Bump X from
# A to B" title — neither is expressible in the convention, and neither is
# something we can rename. It also targets the default branch, so the bypass
# has to sit above the base switch rather than inside the release/v* case: a
# bot PR lands on the trunk directly and the next release branch, cut from the
# trunk, picks it up. Waving it through beats a permanently-red bot PR.
pr-guard: ## Validate a PR's base, branch name and title (env: BASE, HEAD, TITLE).
	@set -eu; \
	: "$${BASE:?BASE is required}" "$${HEAD:?HEAD is required}"; \
	case "$$HEAD" in \
	dependabot/*) \
	  echo "guard skipped for dependabot: $$HEAD -> $$BASE"; exit 0;; \
	esac; \
	case "$$BASE" in \
	$(TRUNK)) \
	  echo "$$HEAD" | grep -Eq '^release/v[0-9]+\.[0-9]+\.[0-9]+$$' \
	    || { echo "::error::$(TRUNK) only accepts PRs from release/vX.Y.Z (got '$$HEAD')"; exit 1; }; \
	  want="release/v$$($(pkg_version))"; \
	  [ "$$want" = "$$HEAD" ] \
	    || { echo "::error::VERSION declares $$want but the branch is $$HEAD"; exit 1; }; \
	  ;; \
	dev|release/v*) \
	  echo "$$HEAD" | grep -Eq '^($(TYPES))/[a-z0-9][a-z0-9._-]*$$' \
	    || { echo "::error::branch must be <type>/<slug> — one of $(TYPES) (got '$$HEAD')"; exit 1; }; \
	  printf '%s' "$${TITLE-}" | grep -Eq '^($(TYPES))(\([a-z0-9._/-]+\))?!?: .+' \
	    || { echo "::error::PR title must read '<type>: summary' (got '$${TITLE-}')"; exit 1; }; \
	  ;; \
	next) \
	  [ "$$HEAD" = "dev" ] || echo "$$HEAD" | grep -Eq '^chore/sync-main-into-next$$' \
	    || { echo "::error::next only accepts PRs from dev (got '$$HEAD')"; exit 1; }; \
	  ;; \
	*/*) \
	  echo "$$BASE" | grep -Eq '^($(TYPES))/[a-z0-9][a-z0-9._-]*$$' \
	    || { echo "::error::stack base must be <type>/<slug> — one of $(TYPES) (got '$$BASE')"; exit 1; }; \
	  echo "$$HEAD" | grep -Eq '^($(TYPES))/[a-z0-9][a-z0-9._-]*$$' \
	    || { echo "::error::branch must be <type>/<slug> — one of $(TYPES) (got '$$HEAD')"; exit 1; }; \
	  printf '%s' "$${TITLE-}" | grep -Eq '^($(TYPES))(\([a-z0-9._/-]+\))?!?: .+' \
	    || { echo "::error::PR title must read '<type>: summary' (got '$${TITLE-}')"; exit 1; }; \
	  ;; \
	*) \
	  echo "::error::$$BASE is not a valid base — target $(TRUNK), next, dev, or a <type>/<slug> branch"; exit 1;; \
	esac; \
	echo "guard passed: $$HEAD -> $$BASE"

release-pr: ## Open or refresh the draft release PR into $(TRUNK) (env: BRANCH).
	@set -eu; \
	branch="$${BRANCH:-$$(git rev-parse --abbrev-ref HEAD)}"; \
	version="$${branch#release/v}"; \
	git fetch --quiet origin \
	  "$(TRUNK):refs/remotes/origin/$(TRUNK)" "$$branch:refs/remotes/origin/$$branch"; \
	body="$$(mktemp)"; \
	{ printf 'Release **v%s**.\n\n## Changes\n\n' "$$version"; \
	  $(MAKE) -s --no-print-directory release-notes RANGE="origin/$(TRUNK)..origin/$$branch"; \
	  printf '\n---\nRefreshed automatically whenever `%s` is updated from `next`.\n' "$$branch"; \
	} > "$$body"; \
	num="$$(gh pr list --base $(TRUNK) --head "$$branch" --state open --json number --jq '.[0].number // empty')"; \
	if [ -n "$$num" ]; then \
	  gh pr edit "$$num" --body-file "$$body"; \
	  echo "refreshed release PR #$$num"; \
	else \
	  gh pr create --draft --base $(TRUNK) --head "$$branch" \
	    --title "release: v$$version" --body-file "$$body"; \
	fi; \
	rm -f "$$body"

release-branch: ## Cut release/v<next> from origin/next (env: VERSION, BUMP).
	@$(MAKE) --no-print-directory cut-release \
	  VERSION="$${VERSION:-$$($(MAKE) -s --no-print-directory next-version)}"

delete-branch: ## Delete a remote branch, tolerating one already gone (env: BRANCH).
	@set -eu; : "$${BRANCH:?BRANCH is required}"; \
	if gh api -X DELETE "repos/$(GH_REPO)/git/refs/heads/$$BRANCH" >/dev/null 2>&1; then \
	  echo "deleted $$BRANCH"; \
	else \
	  echo "$$BRANCH was already gone"; \
	fi

# Idempotent: a tag already released is skipped, not an error.
#
# Must run with the automation App's token, never GITHUB_TOKEN. The tag this
# pushes is what triggers publish.yml (PyPI), and events raised by
# GITHUB_TOKEN do not start workflow runs — it would go silently dead.
tag-release: ## Tag HEAD as v<pyproject version> and publish the GitHub Release.
	@set -eu; \
	tag="v$$($(pkg_version))"; \
	if gh api "repos/$(GH_REPO)/git/ref/tags/$$tag" >/dev/null 2>&1; then \
	  echo "$$tag already exists — skipping"; exit 0; \
	fi; \
	gh release create "$$tag" --target "$$(git rev-parse HEAD)" \
	  --title "$$tag" --generate-notes; \
	echo "released $$tag"

# --- promotion (dev → next → release/v*) ------------------------------------

# Prints: bump insertions deletions total
# bump is major|minor|patch from CHURN_* thresholds.
churn-info: ## Print bump and line counts for FROM...TO (env: FROM, TO).
	@set -eu; \
	: "$${FROM:?FROM is required}" "$${TO:?TO is required}"; \
	stat="$$(git diff --shortstat "$$FROM...$$TO" 2>/dev/null || true)"; \
	ins="$$(printf '%s' "$$stat" | sed -n 's/.* \([0-9][0-9]*\) insertion.*/\1/p')"; \
	del="$$(printf '%s' "$$stat" | sed -n 's/.* \([0-9][0-9]*\) deletion.*/\1/p')"; \
	ins="$${ins:-0}"; del="$${del:-0}"; \
	total=$$((ins + del)); \
	if [ "$$total" -ge $(CHURN_MAJOR) ]; then bump=major; \
	elif [ "$$total" -ge $(CHURN_MINOR) ]; then bump=minor; \
	else bump=patch; \
	fi; \
	printf '%s %s %s %s\n' "$$bump" "$$ins" "$$del" "$$total"

churn-bump: ## Classify a bump from git diff --shortstat (env: FROM, TO).
	@$(MAKE) -s --no-print-directory churn-info FROM="$(FROM)" TO="$(TO)" | awk '{print $$1}'

bootstrap-lanes: ## Create origin/dev and origin/next if they do not exist.
	@set -eu; \
	git fetch --quiet --force --tags origin \
	  "+refs/heads/$(TRUNK):refs/remotes/origin/$(TRUNK)"; \
	if git ls-remote --exit-code --heads origin next >/dev/null 2>&1; then \
	  echo "origin/next already exists"; \
	else \
	  git push origin refs/remotes/origin/$(TRUNK):refs/heads/next; \
	  echo "created origin/next from $(TRUNK)"; \
	fi; \
	if git ls-remote --exit-code --heads origin dev >/dev/null 2>&1; then \
	  echo "origin/dev already exists"; \
	else \
	  ver="$$(git ls-remote --heads origin 'release/v*' \
	    | awk '{print $$2}' \
	    | sed 's|refs/heads/release/v||' \
	    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$$' \
	    | sort -t. -k1,1n -k2,2n -k3,3n \
	    | tail -1 || true)"; \
	  if [ -n "$$ver" ]; then src="release/v$$ver"; \
	  else src=$(TRUNK); \
	  fi; \
	  git fetch --quiet origin "+refs/heads/$$src:refs/remotes/origin/$$src"; \
	  git push origin "refs/remotes/origin/$$src:refs/heads/dev"; \
	  echo "created origin/dev from $$src"; \
	fi

promote-pr: ## Open or refresh the PR from dev into next (env: VERSION, BUMP, CHURN).
	@set -eu; \
	git fetch --quiet --force origin \
	  "+refs/heads/dev:refs/remotes/origin/dev" \
	  "+refs/heads/next:refs/remotes/origin/next"; \
	ahead="$$(git rev-list --count origin/next..origin/dev)"; \
	if [ "$$ahead" -eq 0 ]; then \
	  echo "dev is not ahead of next — nothing to promote"; \
	  exit 0; \
	fi; \
	: "$${VERSION:?VERSION is required}"; \
	stat="$$(git diff --shortstat origin/next...origin/dev || true)"; \
	body="$$(mktemp)"; \
	{ printf 'Promote **v%s** (`%s`%s).\n\n' "$$VERSION" "$${BUMP:-patch}" \
	    "$${CHURN:+, $$CHURN lines of churn}"; \
	  printf '<!-- release: v%s -->\n\n' "$$VERSION"; \
	  printf '%s\n\n' "$${stat:-0 files changed}"; \
	  printf -- '- bump: %s\n' "$${BUMP:-patch}"; \
	} > "$$body"; \
	num="$$(gh pr list --base next --head dev --state open --json number --jq '.[0].number // empty')"; \
	if [ -n "$$num" ]; then \
	  gh pr edit "$$num" --title "chore: promote v$$VERSION to next" --body-file "$$body"; \
	  echo "refreshed promote PR #$$num"; \
	else \
	  gh pr create --base next --head dev \
	    --title "chore: promote v$$VERSION to next" --body-file "$$body"; \
	  num="$$(gh pr list --base next --head dev --state open --json number --jq '.[0].number // empty')"; \
	  echo "opened promote PR #$$num"; \
	fi; \
	rm -f "$$body"; \
	gh pr merge "$$num" --auto --merge

# uv.lock pins the package version, so a bump has to be re-locked and
# committed alongside pyproject.toml.
#
# If an open release/v* → main PR exists, reuse that version and merge
# origin/next in with -X theirs. Do not reset/force-push the in-flight branch
# (that would drop last-minute RC hotfixes). Skip entirely when next and main
# have the same tree — a merge-only sync is not a new release.
sync-lanes: ## Merge origin/$(TRUNK) into next and dev via PRs.
	@set -eu; \
	$(MAKE) --no-print-directory bootstrap-lanes; \
	git fetch --quiet --force origin \
	  "+refs/heads/$(TRUNK):refs/remotes/origin/$(TRUNK)" \
	  "+refs/heads/next:refs/remotes/origin/next" \
	  "+refs/heads/dev:refs/remotes/origin/dev"; \
	for lane in next dev; do \
	  head="chore/sync-main-into-$$lane"; \
	  git checkout --quiet -B "$$head" "origin/$$lane"; \
	  if git merge-base --is-ancestor origin/$(TRUNK) HEAD; then \
	    echo "$$lane already contains $(TRUNK)"; \
	    continue; \
	  fi; \
	  git merge --quiet --no-edit origin/$(TRUNK); \
	  git push --force-with-lease --quiet -u origin "$$head"; \
	  body="$$(mktemp)"; \
	  printf 'Sync **$(TRUNK)** into `%s` after the production release.\n' "$$lane" > "$$body"; \
	  num="$$(gh pr list --base "$$lane" --head "$$head" --state open --json number --jq '.[0].number // empty')"; \
	  if [ -n "$$num" ]; then \
	    gh pr edit "$$num" --title "chore: sync main into $$lane" --body-file "$$body"; \
	    echo "refreshed sync PR #$$num into $$lane"; \
	  else \
	    gh pr create --base "$$lane" --head "$$head" \
	      --title "chore: sync main into $$lane" --body-file "$$body"; \
	    num="$$(gh pr list --base "$$lane" --head "$$head" --state open --json number --jq '.[0].number // empty')"; \
	    echo "opened sync PR #$$num into $$lane"; \
	  fi; \
	  rm -f "$$body"; \
	  gh pr merge "$$num" --auto --merge; \
	done

cleanup-cycle: ## Delete remote feature branches merged into dev, leftover release/v*.
	@set -eu; \
	git fetch --quiet --prune origin; \
	git fetch --quiet --force origin "+refs/heads/dev:refs/remotes/origin/dev"; \
	for ref in $$(git branch -r --merged origin/dev \
	    | sed 's/^[[:space:]]*origin\///' \
	    | grep -E '^($(TYPES))/' || true); do \
	  $(MAKE) -s --no-print-directory delete-branch BRANCH="$$ref"; \
	done; \
	open="$$(gh pr list --base $(TRUNK) --state open --json headRefName \
	  --jq '[.[].headRefName | select(startswith("release/v"))] | join(" ")')"; \
	for ref in $$(git ls-remote --heads origin 'release/v*' \
	    | awk '{print $$2}' | sed 's|refs/heads/||'); do \
	  case " $$open " in *" $$ref "*) continue ;; esac; \
	  $(MAKE) -s --no-print-directory delete-branch BRANCH="$$ref"; \
	done

cleanup-local: ## Delete local feature/release branches whose remotes are gone.
	@set -eu; \
	git fetch --prune --quiet origin; \
	current="$$(git rev-parse --abbrev-ref HEAD)"; \
	for b in $$(git branch --format='%(refname:short)' \
	    | grep -E '^($(TYPES))/|^release/v' || true); do \
	  [ "$$b" = "$$current" ] && continue; \
	  if git ls-remote --exit-code --heads origin "$$b" >/dev/null 2>&1; then \
	    continue; \
	  fi; \
	  git branch -D "$$b"; \
	done

# --- repository settings ----------------------------------------------------

rulesets-diff: ## List the rulesets GitHub currently has, by id and name.
	@gh api "repos/$(GH_REPO)/rulesets" --jq '.[] | "\(.id)\t\(.name)"'

# Matched by `.name`, so a file must keep the name of the ruleset already on
# GitHub or a second one is created alongside it.
rulesets-apply: ## Push .github/rulesets/*.json to GitHub (matched by name).
	@set -eu; \
	for f in .github/rulesets/*.json; do \
	  name="$$(jq -r .name "$$f")"; \
	  id="$$(gh api "repos/$(GH_REPO)/rulesets" --jq ".[] | select(.name==\"$$name\") | .id")"; \
	  if [ -n "$$id" ]; then \
	    gh api -X PUT "repos/$(GH_REPO)/rulesets/$$id" --input "$$f" >/dev/null; \
	    echo "updated $$name"; \
	  else \
	    gh api -X POST "repos/$(GH_REPO)/rulesets" --input "$$f" >/dev/null; \
	    echo "created $$name"; \
	  fi; \
	done

# ── Cleanup ───────────────────────────────────────────────────────────────────

.PHONY: clean-all
