import Foundation

/// Liveness probe payload from `GET /health`.
public struct HealthStatus: Codable, Hashable, Sendable {
    public var status: String
    public var version: String
    public var cacheEntries: Int

    public var isHealthy: Bool { status == "ok" }

    public init(status: String, version: String, cacheEntries: Int) {
        self.status = status
        self.version = version
        self.cacheEntries = cacheEntries
    }
}
