import Foundation

/// The HTTP 300 payload the API returns when a query is ambiguous.
public struct DisambiguationResult: Codable, Hashable, Sendable {
    public var status: Int
    public var message: String
    public var matches: [BookMatch]

    public init(status: Int = 300, message: String, matches: [BookMatch]) {
        self.status = status
        self.message = message
        self.matches = matches
    }
}
