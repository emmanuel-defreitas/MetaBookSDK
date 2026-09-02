import Foundation

/// Where an uploaded EPUB now lives in Vercel Blob storage.
public struct BlobInfo: Codable, Hashable, Sendable {
    public var url: URL
    public var pathname: String
    public var sizeBytes: Int

    public init(url: URL, pathname: String, sizeBytes: Int) {
        self.url = url
        self.pathname = pathname
        self.sizeBytes = sizeBytes
    }
}
