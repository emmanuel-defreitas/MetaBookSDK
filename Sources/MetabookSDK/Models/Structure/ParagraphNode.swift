import Foundation

/// The leaf of the structure tree: a paragraph, or a verse for scripture.
public struct ParagraphNode: Codable, Hashable, Identifiable, Sendable {
    public var index: Int
    public var sentenceCount: Int
    public var wordCount: Int
    public var avgWordsPerSentence: Double
    /// Populated only when ``DetailLevel/sentence`` or deeper is requested.
    public var sentences: [SentenceNode]?

    public var id: Int { index }

    public init(
        index: Int,
        sentenceCount: Int,
        wordCount: Int,
        avgWordsPerSentence: Double,
        sentences: [SentenceNode]? = nil
    ) {
        self.index = index
        self.sentenceCount = sentenceCount
        self.wordCount = wordCount
        self.avgWordsPerSentence = avgWordsPerSentence
        self.sentences = sentences
    }
}
