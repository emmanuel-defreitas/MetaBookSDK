import Foundation

/// The structural shape the detector assigned to a book.
public enum SchemaType: String, Codable, CaseIterable, Hashable, Sendable {
    case canonicalScripture = "canonical_scripture"
    case sectionedBook = "sectioned_book"
    case standardBook = "standard_book"
    case essayCollection = "essay_or_story_collection"
    case flat

    /// A short human-readable name suitable for labels.
    public var displayName: String {
        switch self {
        case .canonicalScripture: "Scripture"
        case .sectionedBook: "Sectioned book"
        case .standardBook: "Standard book"
        case .essayCollection: "Essay or story collection"
        case .flat: "Flat"
        }
    }

    /// An SF Symbol that hints at the schema's shape.
    public var systemImage: String {
        switch self {
        case .canonicalScripture: "books.vertical"
        case .sectionedBook: "square.stack.3d.up"
        case .standardBook: "book"
        case .essayCollection: "doc.on.doc"
        case .flat: "text.justify"
        }
    }
}
