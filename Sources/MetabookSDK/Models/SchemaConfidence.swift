import Foundation

/// How sure the detector is about the assigned ``SchemaType``.
public enum SchemaConfidence: String, Codable, CaseIterable, Hashable, Sendable {
    case high
    case medium
    case low

    public var displayName: String {
        switch self {
        case .high: "High"
        case .medium: "Medium"
        case .low: "Low"
        }
    }
}
