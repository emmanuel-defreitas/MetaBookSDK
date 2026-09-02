import Foundation

/// The outcome of a structure lookup: either a full analysis or a list of candidates to choose from.
public enum StructureLookup: Sendable {
    /// Exactly one book matched and was analysed.
    case found(BookStructureResponse)
    /// Several books matched. Retry with ``BookQuery/gutenbergId(_:)`` for one of the candidates.
    case ambiguous(DisambiguationResult)

    /// The analysed response, if the lookup was not ambiguous.
    public var response: BookStructureResponse? {
        if case .found(let response) = self { response } else { nil }
    }

    /// The candidate list, if the lookup was ambiguous.
    public var matches: [BookMatch] {
        if case .ambiguous(let result) = self { result.matches } else { [] }
    }
}
