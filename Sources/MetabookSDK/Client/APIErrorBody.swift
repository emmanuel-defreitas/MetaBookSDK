import Foundation

/// FastAPI wraps failures as `{"detail": ...}` where `detail` is either a string or an object
/// carrying an `error` code plus context. This decodes both shapes without losing information.
struct APIErrorBody: Decodable {
    var code: String?
    var message: String?
    var gutenbergId: Int?
    var maxBytes: Int?
    var allowed: [String]?

    private enum RootKeys: String, CodingKey { case detail }
    private enum DetailKeys: String, CodingKey { case error, message, gutenbergId, maxBytes, allowed }

    init(from decoder: any Decoder) throws {
        let root = try decoder.container(keyedBy: RootKeys.self)
        if let text = try? root.decode(String.self, forKey: .detail) {
            message = text
            return
        }
        let detail = try root.nestedContainer(keyedBy: DetailKeys.self, forKey: .detail)
        code = try detail.decodeIfPresent(String.self, forKey: .error)
        message = try detail.decodeIfPresent(String.self, forKey: .message)
        gutenbergId = try detail.decodeIfPresent(Int.self, forKey: .gutenbergId)
        maxBytes = try detail.decodeIfPresent(Int.self, forKey: .maxBytes)
        allowed = try detail.decodeIfPresent([String].self, forKey: .allowed)
    }

    /// Parses the body if it is a FastAPI error envelope, otherwise returns `nil`.
    static func parse(_ data: Data) -> APIErrorBody? {
        try? MetabookJSON.decoder.decode(APIErrorBody.self, from: data)
    }
}
