import Foundation

/// A sentence within a paragraph. Present only when ``DetailLevel/sentence`` or deeper is requested.
public struct SentenceNode: Codable, Hashable, Identifiable, Sendable {
    public var index: Int
    public var clauseCount: Int
    public var wordCount: Int
    /// Populated only when ``DetailLevel/clause`` or deeper is requested.
    public var clauses: [ClauseNode]?

    public var id: Int { index }

    public init(index: Int, clauseCount: Int, wordCount: Int, clauses: [ClauseNode]? = nil) {
        self.index = index
        self.clauseCount = clauseCount
        self.wordCount = wordCount
        self.clauses = clauses
    }
}
