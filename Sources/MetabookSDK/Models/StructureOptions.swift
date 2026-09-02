import Foundation

/// Tunables shared by the structure and upload endpoints.
public struct StructureOptions: Hashable, Sendable {
    /// ISO 639-1 language filter applied to Gutendex searches. Ignored for uploads.
    public var language: String
    /// Whether per-paragraph nodes are included beneath each chapter.
    public var includeParagraphs: Bool
    /// Leaf nesting depth beneath each paragraph.
    public var detail: DetailLevel

    public init(language: String = "en", includeParagraphs: Bool = true, detail: DetailLevel = .paragraph) {
        self.language = language
        self.includeParagraphs = includeParagraphs
        self.detail = detail
    }

    public static let `default` = StructureOptions()

    func queryItems(includingLanguage: Bool) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "include_paragraphs", value: includeParagraphs ? "true" : "false"),
            URLQueryItem(name: "detail", value: detail.rawValue),
        ]
        if includingLanguage {
            items.insert(URLQueryItem(name: "language", value: language), at: 0)
        }
        return items
    }
}
