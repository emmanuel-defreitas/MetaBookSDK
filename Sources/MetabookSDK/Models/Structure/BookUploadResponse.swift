import Foundation

/// Full payload from `POST /api/books/upload`.
public struct BookUploadResponse: Codable, Hashable, Sendable {
    public var book: UploadedBookInfo
    public var blob: BlobInfo
    public var structure: StructureDetail
    public var meta: UploadMetaInfo

    public init(book: UploadedBookInfo, blob: BlobInfo, structure: StructureDetail, meta: UploadMetaInfo) {
        self.book = book
        self.blob = blob
        self.structure = structure
        self.meta = meta
    }
}
