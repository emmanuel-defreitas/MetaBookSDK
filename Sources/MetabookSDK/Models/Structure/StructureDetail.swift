import Foundation

/// The detected schema, its confidence, aggregate counts, and the node tree.
public struct StructureDetail: Codable, Hashable, Sendable {
    public var schemaType: SchemaType
    public var schemaConfidence: SchemaConfidence
    public var summary: StructureSummary
    public var nodes: [StructureNode]

    private enum CodingKeys: String, CodingKey {
        case schemaType = "schema"
        case schemaConfidence
        case summary
        case nodes
    }

    public init(
        schemaType: SchemaType,
        schemaConfidence: SchemaConfidence,
        summary: StructureSummary,
        nodes: [StructureNode]
    ) {
        self.schemaType = schemaType
        self.schemaConfidence = schemaConfidence
        self.summary = summary
        self.nodes = nodes
    }
}
