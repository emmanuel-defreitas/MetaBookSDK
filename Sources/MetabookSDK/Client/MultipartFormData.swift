import Foundation

/// Minimal `multipart/form-data` builder for the EPUB upload endpoint.
struct MultipartFormData {
    let boundary: String
    private(set) var body = Data()

    init(boundary: String = "MetabookSDK-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    var contentType: String { "multipart/form-data; boundary=\(boundary)" }

    mutating func addFile(name: String, filename: String, mimeType: String, data: Data) {
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.append("\r\n")
    }

    /// Terminates the body. Call once, after all parts are added.
    func finalized() -> Data {
        var closed = body
        closed.append("--\(boundary)--\r\n")
        return closed
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
