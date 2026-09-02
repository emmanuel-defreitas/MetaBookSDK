import Foundation

/// Request metadata attached to an EPUB upload response.
public struct UploadMetaInfo: Codable, Hashable, Sendable {
    public var uploadedAt: Date
    public var spineDocumentCount: Int
    public var processingTimeMs: Int

    public init(uploadedAt: Date, spineDocumentCount: Int, processingTimeMs: Int) {
        self.uploadedAt = uploadedAt
        self.spineDocumentCount = spineDocumentCount
        self.processingTimeMs = processingTimeMs
    }
}
