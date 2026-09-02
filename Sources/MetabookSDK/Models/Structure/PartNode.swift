import Foundation

/// A top-level node: a part, volume, section, or book.
public struct PartNode: Codable, Hashable, Identifiable, Sendable {
    /// One of `part`, `volume`, `section`, or `book`.
    public var level: String
    public var index: Int
    public var label: String
    public var childCount: Int
    public var totalParagraphs: Int
    public var totalWords: Int
    public var children: [ChapterNode]

    public var id: Int { index }

    public init(
        level: String,
        index: Int,
        label: String,
        childCount: Int,
        totalParagraphs: Int,
        totalWords: Int,
        children: [ChapterNode]
    ) {
        self.level = level
        self.index = index
        self.label = label
        self.childCount = childCount
        self.totalParagraphs = totalParagraphs
        self.totalWords = totalWords
        self.children = children
    }
}
