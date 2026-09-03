# Branching and release

Two long-lived integration lanes (`dev`, `next`) plus `main` and the tags.
Release branches are temporary and versioned. Same model as
[metabook-py](https://github.com/emmanuel-defreitas/metabook-py/blob/main/.github/WORKFLOW.md).

```
<type>/<slug> ──PR──> dev ──PR──> next ──cut──> release/vX.Y.Z ──draft PR──> main ──tag──> vX.Y.Z
                 (deleted on merge)  (staging)                    (deleted on release)   (publish.yml)
```

## Feature branches

Named `<type>/<slug>` with `<type>` one of `feat`, `fix`, `chore`, `docs`,
`ci`, `refactor`, `test`, `perf`, `build`, `style`, `revert`. Git forbids `:`
in a ref, so the conventional-commit form is the **PR title**:
`feat: add upload progress` (an optional scope `feat(client): …` and a `!`
for breaking changes are accepted).

Branch off `dev` and open a PR back into it. Drafts only run `guard`; marking
the PR ready runs `check` (lint, build, tests, iOS Simulator build) and the AI
review. `guard` and `check` are required, and `dev` only accepts
`<type>/<slug>` heads. Merge with **squash**. The branch deletes itself.

Stacked PRs (`feat/b → feat/a → dev`) pass the guard as long as every branch
and title follow the convention.

## `dev` → `next`

`next` is staging. Only `dev` may open a PR into `next` (plus the
post-release `chore/sync-main-into-next`). Open it yourself, or run
**Promote to next** (Actions → workflow_dispatch, or the 22:00 UTC cron) to
have it opened, versioned, and auto-merged. Merge with **merge commit**.

## `next` → `release/vX.Y.Z`

Every push to `next` runs `next.yml`, which:

1. **Estimates the change level** from the churn between `main` and `next`
   (insertions + deletions):

   | Churn | Bump | Semver | Label |
   |-------|------|--------|-------|
   | `< 100` | `patch` | `0.0.+1` | minor |
   | `100–999` | `minor` | `0.+1.0` | major |
   | `≥ 1000` | `major` | `+1.0.0` | breaking |

   A `<!-- release: vX.Y.Z -->` marker left by the promote PR wins; a
   `workflow_dispatch` with `bump` set overrides both.
2. **Checks out `release/vX.Y.Z` from `next`**, writes `X.Y.Z` into `VERSION`
   and `Sources/MetabookSDK/MetabookSDKInfo.swift`, commits
   `chore(release): open vX.Y.Z`, and pushes.
3. That push runs `pr-merged.yml`, which **opens (or refreshes) a draft PR**
   from `release/vX.Y.Z` into `main` with generated release notes.

Exactly one release is in flight at a time: while a draft PR into `main` is
open, later pushes to `next` fast-forward that same branch and keep its
version. Last-minute fixes may PR `<type>/<slug>` directly into the release
branch.

## Ready for review → `main`

Mark the draft **ready for review**. `pr.yml` then runs `check` and, because
the base is `main`, `package`: a release build plus `swift package
archive-source`, uploaded as the `MetabookSDK-dist` artifact. `main` only
accepts `release/vX.Y.Z` heads, and the guard refuses a branch whose name
disagrees with `VERSION`. Merge with **merge commit**.

## After the merge

`release.yml`:

1. tags `vX.Y.Z` and creates the GitHub Release with generated notes;
2. deletes the release branch;
3. opens auto-merging PRs that sync `main` back into `next` and `dev`;
4. deletes every remote feature branch already merged into `dev` and any
   leftover `release/v*` branch with no open PR.

The tag triggers `publish.yml`, which rebuilds the source archive, attaches
`MetabookSDK-vX.Y.Z.zip` (+ sha256) to the release, and nudges the Swift
Package Index. SPI ingests tags on its own once the package is listed; the
job's summary says whether it is (see [Swift Package Index](#swift-package-index)).

## Swift Package Index

Listing is a **one-time** manual step. Once the package is on the index, SPI
polls GitHub and ingests every later tag on its own — there is nothing to
repeat per release.

Before submitting, run the preflight:

```bash
make spi-check
```

It asserts each requirement from the add-a-package page against this
repository — public, `Package.swift` in the root, Swift 5.0+, a `vX.Y.Z` tag,
valid `swift package dump-package` output, an `https://…​.git` URL, and a
clean build — plus the parts SPI's builder enforces silently: `.spi.yml` under
its 1500-byte read limit, `platform:` values drawn from the builder's platform
list, and `documentation_targets` naming targets `Package.swift` actually
declares. A bad `.spi.yml` does not fail loudly; it just produces no docs.

`make spi-check` fails until `v0.0.1` exists, because SPI has nothing to
ingest from an untagged repository. So the order is: merge the release PR →
`release.yml` tags the version → `make spi-check` passes → submit.

To submit, sign in at <https://swiftpackageindex.com/add-a-package> and paste
the URL that `make spi-url` prints:

```
https://github.com/emmanuel-defreitas/MetaBookSDK.git
```

The form opens a PR against `SwiftPackageIndex/PackageList` under your own
GitHub account, which is why it is not automated here. A maintainer merges it,
and the package appears at
<https://swiftpackageindex.com/emmanuel-defreitas/MetaBookSDK>.

Afterwards, `publish.yml` flips its step summary from "not listed yet" to the
package URL on every release, so a package that silently falls off the index
shows up in CI. The README badges resolve once the first ingest completes —
until then shields.io renders them as unavailable, which is expected.

Docs are configured by `.spi.yml`: SPI builds DocC for `MetabookSDK` on the
`ios` and `macos-spm` builder platforms and hosts it from the package page.

## Workflows

| File | Trigger | Does |
|------|---------|------|
| `pr.yml` | PR opened / ready / pushed | `guard`, `check`, `package` (into main), `review` |
| `promote.yml` | 22:00 UTC daily / manual | open `dev → next` PR, auto-merge |
| `next.yml` | push to `next` / manual | estimate bump, cut or refresh `release/v*` |
| `pr-merged.yml` | push to `release/v*` | upsert the draft PR into `main` |
| `release.yml` | PR merged into `main` / manual | tag, release, sync lanes, cleanup |
| `publish.yml` | `vX.Y.Z` tag | attach the archive, notify SPI |
| `automerge.yml` | Dependabot PR | auto-merge |

Every step is a `make` target (`make help`).

## Rulesets

`.github/rulesets/*.json` are applied with `make rulesets-apply`:

| Ruleset | Rules |
|---------|-------|
| main | no deletion / force-push; PRs only, merge commits; `guard`, `check`, `package` required |
| next | same, `guard` + `check` required |
| dev | same, squash or merge; `guard` + `check` required |
| release/v* | no force-push; PRs, `guard` + `check` required; creation/deletion left open for the automation |
| tags v* | no create / update / delete except by bypass actors |

Bypass actors: repository admins and the automation App (Integration
`4752984`, the same one metabook-py uses). On `dev` and `next` the bypass is
**pull-request only**: nobody may push to or delete those lanes directly, which
is what stops the repository's head-branch auto-delete from removing `dev`
after a promote PR merges. The sync and promote flows only ever open PRs.

## Secrets

| Name | Used by |
|------|---------|
| `AUTOMATION_APP_ID` / `AUTOMATION_APP_PRIVATE_KEY` | promote, next, pr-merged, release |
| `CLAUDE_CODE_OAUTH_TOKEN` | the AI review (optional; skips with a note if unset) |

The App must be **installed on this repository**. Without it, PRs opened by
`GITHUB_TOKEN` cannot trigger their own required checks.

## Bootstrap

`dev` and `next` were created from `main` at repository creation. To recreate
them: run **Release** manually, or `make bootstrap-lanes`.

Useful targets:

```bash
make ci                          # what CI runs on a PR
make pack                        # the source archive attached to releases
make next-version BUMP=patch     # what the next tag would be called
make churn-info FROM=origin/main TO=origin/next
make cleanup-local               # prune local feature / release branches
make rulesets-diff && make rulesets-apply
```
