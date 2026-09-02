import Foundation

/// Connection settings for a ``MetabookClient``.
public struct MetabookConfiguration: Sendable {
    /// Root of the deployment, with no trailing path. The client appends `/api/...` and `/health`.
    public var baseURL: URL
    /// Per-request timeout. Full-text analysis of a long book can take several seconds.
    public var timeout: TimeInterval
    /// Extra headers sent with every request, for example an auth token behind a proxy.
    public var additionalHeaders: [String: String]

    public init(
        baseURL: URL,
        timeout: TimeInterval = 60,
        additionalHeaders: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.additionalHeaders = additionalHeaders
    }

    /// Targets a locally running `make dev` server.
    public static let localhost = MetabookConfiguration(
        baseURL: URL(string: "http://127.0.0.1:8000") ?? URL(fileURLWithPath: "/")
    )
}
