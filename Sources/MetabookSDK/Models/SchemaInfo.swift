import Foundation

/// Describes one structural schema the detector can identify.
public struct SchemaInfo: Codable, Hashable, Identifiable, Sendable {
    public var name: SchemaType
    public var description: String
    public var hierarchy: [String]

    public var id: SchemaType { name }

    public init(name: SchemaType, description: String, hierarchy: [String]) {
        self.name = name
        self.description = description
        self.hierarchy = hierarchy
    }
}
