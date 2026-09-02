import Foundation

/// Lifecycle of a single EPUB upload as driven by ``BookStructureModel``.
public enum UploadState: Sendable {
    case idle
    case uploading
    case loaded(BookUploadResponse)
    case failed(MetabookError)

    public var isUploading: Bool {
        if case .uploading = self { true } else { false }
    }

    public var response: BookUploadResponse? {
        if case .loaded(let response) = self { response } else { nil }
    }

    public var error: MetabookError? {
        if case .failed(let error) = self { error } else { nil }
    }
}
