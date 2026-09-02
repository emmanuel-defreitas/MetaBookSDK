import Foundation

/// Default ``MetabookTransport`` backed by `URLSession`.
public struct URLSessionTransport: MetabookTransport {
    public var session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw MetabookError.transport(URLError(.badServerResponse))
        }
        return (data, http)
    }
}
