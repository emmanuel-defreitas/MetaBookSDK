import Foundation

/// Lifecycle of a single book analysis as driven by ``BookStructureModel``.
public enum BookLookupState: Sendable {
    case idle
    case loading
    case loaded(BookStructureResponse)
    case ambiguous([BookMatch])
    case failed(MetabookError)

    public var isLoading: Bool {
        if case .loading = self { true } else { false }
    }

    public var response: BookStructureResponse? {
        if case .loaded(let response) = self { response } else { nil }
    }

    public var matches: [BookMatch] {
        if case .ambiguous(let matches) = self { matches } else { [] }
    }

    public var error: MetabookError? {
        if case .failed(let error) = self { error } else { nil }
    }
}
