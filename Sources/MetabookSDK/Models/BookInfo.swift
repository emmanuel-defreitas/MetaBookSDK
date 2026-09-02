import Foundation

/// Metadata for a book located on Project Gutenberg.
public struct BookInfo: Codable, Hashable, Identifiable, Sendable {
    public var gutenbergId: Int
    public var title: String
    public var authors: [AuthorInfo]
    public var language: String
    public var subjects: [String]

    /// Stable identity derived from the Gutenberg catalogue number.
    public var id: Int { gutenbergId }

    public init(
        gutenbergId: Int,
        title: String,
        authors: [AuthorInfo] = [],
        language: String = "en",
        subjects: [String] = []
    ) {
        self.gutenbergId = gutenbergId
        self.title = title
        self.authors = authors
        self.language = language
        self.subjects = subjects
    }
}
