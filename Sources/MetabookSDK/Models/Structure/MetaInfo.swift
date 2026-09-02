import Foundation

/// Request metadata attached to a Gutenberg structure response.
public struct MetaInfo: Codable, Hashable, Sendable {
    public var fetchedAt: Date
    public var cached: Bool
    public var processingTimeMs: Int

    public init(fetchedAt: Date, cached: Bool, processingTimeMs: Int) {
        self.fetchedAt = fetchedAt
        self.cached = cached
        self.processingTimeMs = processingTimeMs
    }
}
