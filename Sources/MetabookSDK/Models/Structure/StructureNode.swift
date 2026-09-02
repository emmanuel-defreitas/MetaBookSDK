import Foundation

/// One entry of ``StructureDetail/nodes``. The API returns a heterogeneous list whose element kind
/// depends on the detected schema, so the SDK discriminates on the keys present in each object.
public enum StructureNode: Hashable, Identifiable, Sendable {
    case part(PartNode)
    case chapter(ChapterNode)
    case paragraph(ParagraphNode)

    public var id: Int {
        switch self {
        case .part(let node): node.index
        case .chapter(let node): node.index
        case .paragraph(let node): node.index
        }
    }

    /// The node's display label. Paragraphs have none, so a positional label is synthesised.
    public var label: String {
        switch self {
        case .part(let node): node.label
        case .chapter(let node): node.label
        case .paragraph(let node): "Paragraph \(node.index + 1)"
        }
    }

    /// Total words beneath this node.
    public var totalWords: Int {
        switch self {
        case .part(let node): node.totalWords
        case .chapter(let node): node.totalWords
        case .paragraph(let node): node.wordCount
        }
    }
}

extension StructureNode: Codable {
    private enum DiscriminatorKeys: String, CodingKey {
        case children
        case paragraphCount
    }

    public init(from decoder: any Decoder) throws {
        let keys = try decoder.container(keyedBy: DiscriminatorKeys.self)
        if keys.contains(.children) {
            self = .part(try PartNode(from: decoder))
        } else if keys.contains(.paragraphCount) {
            self = .chapter(try ChapterNode(from: decoder))
        } else {
            self = .paragraph(try ParagraphNode(from: decoder))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .part(let node): try node.encode(to: encoder)
        case .chapter(let node): try node.encode(to: encoder)
        case .paragraph(let node): try node.encode(to: encoder)
        }
    }
}
