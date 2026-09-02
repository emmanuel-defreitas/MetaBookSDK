import Foundation

/// A purely positional word node. Present only when ``DetailLevel/word`` is requested.
public struct WordNode: Codable, Hashable, Identifiable, Sendable {
    public var index: Int

    public var id: Int { index }

    public init(index: Int) {
        self.index = index
    }
}
