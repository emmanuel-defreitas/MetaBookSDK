import Foundation

/// A mid-level node: a chapter, essay, or story.
public struct ChapterNode: Codable, Hashable, Identifiable, Sendable {
    /// One of `chapter`, `essay`, or `story`.
    public var level: String
    public var index: Int
    public var label: String
    public var paragraphCount: Int
    public var avgSentencesPerParagraph: Double
    public var avgWordsPerSentence: Double
    public var totalWords: Int
    public var totalSentences: Int
    /// `nil` when the request set `includeParagraphs` to `false`.
    public var paragraphs: [ParagraphNode]?

    public var id: Int { index }

    public init(
        level: String,
        index: Int,
        label: String,
        paragraphCount: Int,
        avgSentencesPerParagraph: Double,
        avgWordsPerSentence: Double,
        totalWords: Int,
        totalSentences: Int,
        paragraphs: [ParagraphNode]? = nil
    ) {
        self.level = level
        self.index = index
        self.label = label
        self.paragraphCount = paragraphCount
        self.avgSentencesPerParagraph = avgSentencesPerParagraph
        self.avgWordsPerSentence = avgWordsPerSentence
        self.totalWords = totalWords
        self.totalSentences = totalSentences
        self.paragraphs = paragraphs
    }
}
