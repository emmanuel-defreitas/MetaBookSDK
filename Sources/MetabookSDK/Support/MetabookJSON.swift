import Foundation

/// Shared coders configured for the Metabook API's snake_case keys and ISO 8601 timestamps.
enum MetabookJSON {
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            return try parseDate(raw)
        }
        return decoder
    }()

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    /// Pydantic emits `2026-09-01T02:44:30.123456Z`; tolerate both fractional and whole seconds,
    /// and both `Z` and explicit offsets.
    static func parseDate(_ raw: String) throws -> Date {
        let fractional = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
        if let date = try? fractional.parse(raw) { return date }
        let whole = Date.ISO8601FormatStyle()
        if let date = try? whole.parse(raw) { return date }
        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Unrecognised ISO 8601 date: \(raw)")
        )
    }
}
