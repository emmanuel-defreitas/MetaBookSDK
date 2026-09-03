# MetabookSDK

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Femmanuel-defreitas%2FMetaBookSDK%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/emmanuel-defreitas/MetaBookSDK)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Femmanuel-defreitas%2FMetaBookSDK%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/emmanuel-defreitas/MetaBookSDK)
[![](https://img.shields.io/badge/documentation-gray?logo=swift&logoColor=white)](https://swiftpackageindex.com/emmanuel-defreitas/MetaBookSDK/~/documentation/metabooksdk)

Swift Package for the [metabook-py](https://github.com/emmanuel-defreitas/metabook-py) Book Structure API. Typed models, an async client, `@Observable` view models, and a handful of SwiftUI views so any Swift project can search Project Gutenberg or upload an EPUB and render the resulting structural schema.

No book text ever crosses the wire. Every node carries counts and positions only.

## Requirements

| | Minimum |
|---|---|
| Swift tools | 6.2 |
| iOS | 17 |
| macOS | 14 |

The package builds in Swift 6 language mode with strict concurrency.

## Installation

Add the package in Xcode (File → Add Package Dependencies) or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/emmanuel-defreitas/MetaBookSDK.git", from: "0.0.1"),
],
targets: [
    .target(name: "MyApp", dependencies: ["MetabookSDK"]),
]
```

## Quick start

### Plain Swift

```swift
import MetabookSDK

let client = MetabookClient(configuration: MetabookConfiguration(baseURL: URL(string: "https://metabook.example.com")!))

switch try await client.structure(for: .title("Pride and Prejudice"), options: StructureOptions(detail: .sentence)) {
case .found(let response):
    print(response.structure.schemaType, response.structure.summary.totalWords)
case .ambiguous(let result):
    print("Pick one:", result.matches.map(\.gutenbergId))
}

let upload = try await client.upload(epubAt: fileURL)
let schemas = try await client.schemas()
let health = try await client.health()
```

`MetabookConfiguration.localhost` targets a `make dev` server on `127.0.0.1:8000`.

### SwiftUI

Inject a client once near the root:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .metabookClient(MetabookClient(configuration: .localhost))
        }
    }
}
```

Own a `BookStructureModel` where the work starts and render its state:

```swift
struct ContentView: View {
    @Environment(\.metabookClient) private var client
    @State private var model: BookStructureModel?
    @State private var query = ""

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    BookStructureScreen(model: model)
                }
            }
            .searchable(text: $query)
            .onSubmit(of: .search) { model?.startLoading(.title(query)) }
            .task { model = BookStructureModel(client: client) }
        }
    }
}

struct BookStructureScreen: View {
    @Bindable var model: BookStructureModel

    var body: some View {
        switch model.lookup {
        case .idle:
            ContentUnavailableView("Search for a book", systemImage: "book")
        case .loading:
            ProgressView()
        case .loaded(let response):
            List {
                Section {
                    SchemaBadge(structure: response.structure)
                    StructureSummaryView(summary: response.structure.summary)
                }
            }
            StructureTreeView(structure: response.structure)
        case .ambiguous(let matches):
            BookMatchList(matches: matches) { match in
                Task { await model.select(match) }
            }
        case .failed(let error):
            ContentUnavailableView("Couldn't analyse", systemImage: "exclamationmark.triangle", description: Text(error.localizedDescription))
        }
    }
}
```

`model.upload(epubAt:)` accepts the URL from `fileImporter` and handles security-scoped access.

## What's inside

| Layer | Types |
|---|---|
| Client | `MetabookClient`, `MetabookConfiguration`, `MetabookTransport`, `URLSessionTransport`, `MetabookError` |
| Requests | `BookQuery`, `StructureOptions`, `DetailLevel`, `StructureLookup` |
| Models | `BookStructureResponse`, `BookUploadResponse`, `StructureDetail`, `StructureSummary`, `StructureNode`, `PartNode`, `ChapterNode`, `ParagraphNode`, `SentenceNode`, `ClauseNode`, `WordNode`, `SchemaType`, `SchemaConfidence`, `SchemaInfo`, `BookInfo`, `UploadedBookInfo`, `BookMatch`, `DisambiguationResult`, `BlobInfo`, `HealthStatus` |
| Observable | `BookStructureModel`, `BookLookupState`, `UploadState`, `SchemaCatalogModel` |
| SwiftUI | `StructureTreeView`, `StructureNodeRow`, `StructureSummaryView`, `SchemaBadge`, `BookMatchList`, `StructureOutlineItem`, `\.metabookClient` |

### Error handling

`MetabookError` mirrors every documented status: `bookNotFound`, `textUnavailable`, `invalidRequest`, `gutendexUnavailable(timedOut:)`, `invalidEpub`, `fileTooLarge`, `blobUploadFailed`, plus `unexpectedStatus`, `decoding`, and `transport`. HTTP 300 is not an error; it is `StructureLookup.ambiguous`.

### Testing your own code

`MetabookTransport` is the only network seam. Conform a stub and pass it to `MetabookClient(configuration:transport:)` to replay canned JSON without a server.

## Development

```bash
make ci        # lint, version check, build, tests, iOS Simulator build
make pack      # release build + source archive in dist/
make spi-check # Swift Package Index listing requirements
make help      # everything else
```

Branches, versioning, and the release pipeline are described in [.github/WORKFLOW.md](.github/WORKFLOW.md). In short: feature branches PR into `dev`, `dev` PRs into `next`, a push to `next` cuts `release/vX.Y.Z` with a draft PR into `main`, and merging that tags and publishes the release.

`MetabookSDKInfo.version` reports the version of the SDK you linked.

## License

MIT. See [LICENSE](LICENSE).
