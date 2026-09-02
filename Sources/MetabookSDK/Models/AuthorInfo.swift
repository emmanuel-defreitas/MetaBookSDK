import Foundation

/// An author attached to a book, with optional life dates as reported by Gutendex or the EPUB metadata.
public struct AuthorInfo: Codable, Hashable, Sendable {
    public var name: String
    public var birthYear: Int?
    public var deathYear: Int?

    public init(name: String, birthYear: Int? = nil, deathYear: Int? = nil) {
        self.name = name
        self.birthYear = birthYear
        self.deathYear = deathYear
    }
}
