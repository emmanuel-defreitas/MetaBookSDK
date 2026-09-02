import Foundation

/// The single seam between ``MetabookClient`` and the network. Conform a test double to this
/// to exercise the client without a server.
public protocol MetabookTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
