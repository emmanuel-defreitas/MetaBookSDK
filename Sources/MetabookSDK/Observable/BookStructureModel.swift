import Foundation
import Observation

/// Observable driver for the structure and upload endpoints. Own one with `@State` in the view
/// that starts the work, and hand it down with `@Bindable` or the environment.
///
/// Each `load` or `upload` call cancels any in-flight request of the same kind, so wiring it
/// to a search field's `onSubmit` is safe.
@MainActor
@Observable
public final class BookStructureModel {
    public private(set) var lookup: BookLookupState = .idle
    public private(set) var upload: UploadState = .idle
    public var options: StructureOptions

    /// The structure most recently produced by either path, for views that treat both alike.
    public var structure: StructureDetail? {
        upload.response?.structure ?? lookup.response?.structure
    }

    @ObservationIgnored private let client: MetabookClient
    @ObservationIgnored private var lookupTask: Task<Void, Never>?
    @ObservationIgnored private var uploadTask: Task<Void, Never>?

    public init(client: MetabookClient = MetabookClient(), options: StructureOptions = .default) {
        self.client = client
        self.options = options
    }

    // MARK: - Lookup

    /// Starts a lookup and returns once it settles into ``BookLookupState/loaded(_:)``,
    /// ``BookLookupState/ambiguous(_:)``, or ``BookLookupState/failed(_:)``.
    public func load(_ query: BookQuery) async {
        lookupTask?.cancel()
        let task = Task { await runLookup(query) }
        lookupTask = task
        await task.value
    }

    /// Fire-and-forget variant for button actions and `onSubmit`.
    public func startLoading(_ query: BookQuery) {
        lookupTask?.cancel()
        lookupTask = Task { await runLookup(query) }
    }

    /// Convenience for resolving an ambiguous lookup by picking one candidate.
    public func select(_ match: BookMatch) async {
        await load(.gutenbergId(match.gutenbergId))
    }

    private func runLookup(_ query: BookQuery) async {
        lookup = .loading
        do {
            let result = try await client.structure(for: query, options: options)
            guard !Task.isCancelled else { return }
            switch result {
            case .found(let response): lookup = .loaded(response)
            case .ambiguous(let result): lookup = .ambiguous(result.matches)
            }
        } catch is CancellationError {
            return
        } catch let error as MetabookError {
            guard !Task.isCancelled else { return }
            lookup = .failed(error)
        } catch {
            guard !Task.isCancelled else { return }
            lookup = .failed(.transport(error))
        }
    }

    // MARK: - Upload

    /// Uploads an EPUB from a file URL, such as one returned by `fileImporter`.
    public func upload(epubAt fileURL: URL) async {
        uploadTask?.cancel()
        let client = client
        let options = options
        let task = Task { await runUpload { try await client.upload(epubAt: fileURL, options: options) } }
        uploadTask = task
        await task.value
    }

    /// Uploads in-memory EPUB bytes.
    public func upload(epub data: Data, filename: String) async {
        uploadTask?.cancel()
        let client = client
        let options = options
        let task = Task {
            await runUpload { try await client.upload(epub: data, filename: filename, options: options) }
        }
        uploadTask = task
        await task.value
    }

    private func runUpload(_ work: @escaping @Sendable () async throws -> BookUploadResponse) async {
        upload = .uploading
        do {
            let response = try await work()
            guard !Task.isCancelled else { return }
            upload = .loaded(response)
        } catch is CancellationError {
            return
        } catch let error as MetabookError {
            guard !Task.isCancelled else { return }
            upload = .failed(error)
        } catch {
            guard !Task.isCancelled else { return }
            upload = .failed(.transport(error))
        }
    }

    // MARK: - Control

    /// Cancels in-flight work and returns both states to `.idle`.
    public func reset() {
        lookupTask?.cancel()
        uploadTask?.cancel()
        lookup = .idle
        upload = .idle
    }
}
