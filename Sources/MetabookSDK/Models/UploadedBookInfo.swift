import Foundation

/// Metadata extracted from an uploaded EPUB. Unlike ``BookInfo`` there is no Gutenberg ID.
public struct UploadedBookInfo: Codable, Hashable, Sendable {
    public var source: String
    public var title: String
    public var authors: [AuthorInfo]
    public var language: String
    public var subjects: [String]
    public var isbn: String?

    public init(
        source: String = "upload",
        title: String,
        authors: [AuthorInfo] = [],
        language: String = "en",
        subjects: [String] = [],
        isbn: String? = nil
    ) {
        self.source = source
        self.title = title
        self.authors = authors
        self.language = language
        self.subjects = subjects
        self.isbn = isbn
    }
}
