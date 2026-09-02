import Foundation

@testable import MetabookSDK

/// Records the last request and replays a canned response.
final class MockTransport: MetabookTransport, @unchecked Sendable {
    struct Reply {
        var status: Int
        var body: Data
    }

    private let lock = NSLock()
    private var _requests: [URLRequest] = []
    private var reply: Reply

    init(status: Int = 200, body: Data = Data()) {
        reply = Reply(status: status, body: body)
    }

    convenience init(status: Int = 200, json: String) {
        self.init(status: status, body: Data(json.utf8))
    }

    var requests: [URLRequest] {
        lock.withLock { _requests }
    }

    var lastRequest: URLRequest? { requests.last }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lock.withLock { _requests.append(request) }
        let url = request.url ?? URL(fileURLWithPath: "/")
        let response = HTTPURLResponse(url: url, statusCode: reply.status, httpVersion: nil, headerFields: nil)
        guard let response else { throw URLError(.badServerResponse) }
        return (reply.body, response)
    }
}
