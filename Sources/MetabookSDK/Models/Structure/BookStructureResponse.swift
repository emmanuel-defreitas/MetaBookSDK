import Foundation

/// Full payload from `GET /api/books/structure`.
public struct BookStructureResponse: Codable, Hashable, Sendable {
    public var book: BookInfo
    public var structure: StructureDetail
    public var meta: MetaInfo

    public init(book: BookInfo, structure: StructureDetail, meta: MetaInfo) {
        self.book = book
        self.structure = structure
        self.meta = meta
    }
}
