import Foundation

/// A lightweight candidate returned when a title search matches more than one book.
public struct BookMatch: Codable, Hashable, Identifiable, Sendable {
    public var gutenbergId: Int
    public var title: String
    public var authors: [String]
    public var language: String

    public var id: Int { gutenbergId }

    public init(gutenbergId: Int, title: String, authors: [String] = [], language: String = "en") {
        self.gutenbergId = gutenbergId
        self.title = title
        self.authors = authors
        self.language = language
    }
}
