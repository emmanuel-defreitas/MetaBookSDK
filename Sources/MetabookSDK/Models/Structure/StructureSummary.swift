import Foundation

/// Whole-book aggregate counts.
public struct StructureSummary: Codable, Hashable, Sendable {
    public var totalTopLevelNodes: Int
    /// `nil` for `flat` and `standard_book` schemas, which have no mid level.
    public var totalMidLevelNodes: Int?
    public var totalParagraphs: Int
    public var totalSentences: Int
    public var totalWords: Int
    public var avgParagraphsPerChapter: Double
    public var avgSentencesPerParagraph: Double
    public var avgWordsPerSentence: Double

    public init(
        totalTopLevelNodes: Int,
        totalMidLevelNodes: Int? = nil,
        totalParagraphs: Int,
        totalSentences: Int,
        totalWords: Int,
        avgParagraphsPerChapter: Double,
        avgSentencesPerParagraph: Double,
        avgWordsPerSentence: Double
    ) {
        self.totalTopLevelNodes = totalTopLevelNodes
        self.totalMidLevelNodes = totalMidLevelNodes
        self.totalParagraphs = totalParagraphs
        self.totalSentences = totalSentences
        self.totalWords = totalWords
        self.avgParagraphsPerChapter = avgParagraphsPerChapter
        self.avgSentencesPerParagraph = avgSentencesPerParagraph
        self.avgWordsPerSentence = avgWordsPerSentence
    }
}
