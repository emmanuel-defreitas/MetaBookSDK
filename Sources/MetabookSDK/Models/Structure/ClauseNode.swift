import Foundation

/// A clause within a sentence. Present only when ``DetailLevel/clause`` or deeper is requested.
public struct ClauseNode: Codable, Hashable, Identifiable, Sendable {
    public var index: Int
    public var wordCount: Int
    /// Populated only when ``DetailLevel/word`` is requested.
    public var words: [WordNode]?

    public var id: Int { index }

    public init(index: Int, wordCount: Int, words: [WordNode]? = nil) {
        self.index = index
        self.wordCount = wordCount
        self.words = words
    }
}
