import Foundation

/// How to locate a book on Project Gutenberg. Exactly one identifier is used per request.
public enum BookQuery: Hashable, Sendable {
    /// Fuzzy title search via Gutendex. May yield an ambiguous result.
    case title(String)
    /// ISBN-10 or ISBN-13.
    case isbn(String)
    /// A Project Gutenberg catalogue number.
    case gutenbergId(Int)

    /// The query-string items the API expects for this lookup.
    var queryItems: [URLQueryItem] {
        switch self {
        case .title(let title): [URLQueryItem(name: "title", value: title)]
        case .isbn(let isbn): [URLQueryItem(name: "isbn", value: isbn)]
        case .gutenbergId(let id): [URLQueryItem(name: "gutenberg_id", value: String(id))]
        }
    }
}
