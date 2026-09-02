import Foundation

/// How deep the returned tree nests beneath each paragraph.
public enum DetailLevel: String, Codable, CaseIterable, Hashable, Sendable, Comparable {
    case paragraph
    case sentence
    case clause
    case word

    private var rank: Int {
        switch self {
        case .paragraph: 0
        case .sentence: 1
        case .clause: 2
        case .word: 3
        }
    }

    public static func < (lhs: DetailLevel, rhs: DetailLevel) -> Bool {
        lhs.rank < rhs.rank
    }

    public var displayName: String {
        switch self {
        case .paragraph: "Paragraph"
        case .sentence: "Sentence"
        case .clause: "Clause"
        case .word: "Word"
        }
    }
}
