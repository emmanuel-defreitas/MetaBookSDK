import Foundation

/// A flattened, `Identifiable` projection of the node tree for `List` and `OutlineGroup`.
/// Identity is the path from the root, so equal indices at different depths never collide.
public struct StructureOutlineItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let levelName: String
    public let wordCount: Int
    public let childSummary: String?
    public let children: [StructureOutlineItem]?

    public init(
        id: String,
        title: String,
        levelName: String,
        wordCount: Int,
        childSummary: String?,
        children: [StructureOutlineItem]?
    ) {
        self.id = id
        self.title = title
        self.levelName = levelName
        self.wordCount = wordCount
        self.childSummary = childSummary
        self.children = children
    }

    /// Builds the outline for a full structure payload.
    public static func items(for structure: StructureDetail) -> [StructureOutlineItem] {
        structure.nodes.map { item(for: $0, path: "root") }
    }

    static func item(for node: StructureNode, path: String) -> StructureOutlineItem {
        switch node {
        case .part(let part):
            let id = "\(path)/\(part.level)-\(part.index)"
            return StructureOutlineItem(
                id: id,
                title: part.label,
                levelName: part.level,
                wordCount: part.totalWords,
                childSummary: "\(part.childCount) \(part.children.first?.level ?? "chapter")s",
                children: part.children.map { item(for: .chapter($0), path: id) }
            )
        case .chapter(let chapter):
            let id = "\(path)/\(chapter.level)-\(chapter.index)"
            return StructureOutlineItem(
                id: id,
                title: chapter.label,
                levelName: chapter.level,
                wordCount: chapter.totalWords,
                childSummary: "\(chapter.paragraphCount) paragraphs",
                children: chapter.paragraphs?.map { item(for: .paragraph($0), path: id) }
            )
        case .paragraph(let paragraph):
            return StructureOutlineItem(
                id: "\(path)/paragraph-\(paragraph.index)",
                title: node.label,
                levelName: "paragraph",
                wordCount: paragraph.wordCount,
                childSummary: "\(paragraph.sentenceCount) sentences",
                children: nil
            )
        }
    }
}
