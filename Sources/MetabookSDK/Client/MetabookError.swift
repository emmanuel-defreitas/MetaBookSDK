import Foundation

/// Every failure the SDK can surface, mirroring the API's documented status codes.
public enum MetabookError: Error, Sendable {
    /// 404: no book matched the query.
    case bookNotFound(BookQuery)
    /// 422: the book was found but Gutenberg served no usable text.
    case textUnavailable(gutenbergId: Int?)
    /// 422 with an unexpected body, or a validation failure such as a bad `detail` value.
    case invalidRequest(message: String)
    /// 502 or 504: Gutendex could not be reached.
    case gutendexUnavailable(message: String, timedOut: Bool)
    /// 400: the uploaded file was not a parseable EPUB.
    case invalidEpub(message: String)
    /// 413: the upload exceeded the server limit.
    case fileTooLarge(maxBytes: Int?)
    /// 502 on upload: storing the file in Vercel Blob failed.
    case blobUploadFailed(message: String)
    /// Any other non-success status.
    case unexpectedStatus(code: Int, body: String)
    /// The body could not be decoded into the expected model.
    case decoding(any Error)
    /// The request never produced an HTTP response.
    case transport(any Error)
}

extension MetabookError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .bookNotFound:
            "No book matched that query."
        case .textUnavailable(let id):
            if let id {
                "The text for Gutenberg book #\(id) could not be retrieved."
            } else {
                "The book's text could not be retrieved."
            }
        case .invalidRequest(let message):
            message
        case .gutendexUnavailable(let message, let timedOut):
            timedOut ? "Gutendex timed out: \(message)" : "Gutendex is unreachable: \(message)"
        case .invalidEpub(let message):
            "Invalid EPUB: \(message)"
        case .fileTooLarge(let maxBytes):
            if let maxBytes {
                "The file exceeds the upload limit of \(maxBytes) bytes."
            } else {
                "The file exceeds the upload limit."
            }
        case .blobUploadFailed(let message):
            "Upload to storage failed: \(message)"
        case .unexpectedStatus(let code, _):
            "The server returned an unexpected status (\(code))."
        case .decoding(let error):
            "The response could not be read: \(error.localizedDescription)"
        case .transport(let error):
            error.localizedDescription
        }
    }
}
