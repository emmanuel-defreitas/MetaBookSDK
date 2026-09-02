import Foundation
import Testing

@testable import MetabookSDK

@Suite("Decoding")
struct DecodingTests {
    @Test("Structure response decodes nested part → chapter → paragraph → sentence → clause → word")
    func decodesDeepTree() throws {
        let response = try MetabookJSON.decoder.decode(BookStructureResponse.self, from: Data(Fixtures.structure.utf8))

        #expect(response.book.gutenbergId == 1342)
        #expect(response.book.authors.first?.birthYear == 1775)
        #expect(response.structure.schemaType == .sectionedBook)
        #expect(response.structure.schemaConfidence == .medium)
        #expect(response.structure.summary.totalMidLevelNodes == 2)
        #expect(response.meta.cached == false)
        #expect(response.meta.processingTimeMs == 812)

        guard case .part(let volume) = response.structure.nodes.first else {
            Issue.record("Expected a part node")
            return
        }
        #expect(volume.level == "volume")
        #expect(volume.children.count == 2)
        #expect(volume.children[1].paragraphs == nil)

        let paragraph = try #require(volume.children[0].paragraphs?.first)
        let sentence = try #require(paragraph.sentences?.first)
        let clause = try #require(sentence.clauses?.first)
        #expect(clause.words?.first?.index == 0)
    }

    @Test("Flat schema decodes paragraph nodes at the top level and a null mid-level count")
    func decodesFlatTree() throws {
        let response = try MetabookJSON.decoder.decode(
            BookStructureResponse.self, from: Data(Fixtures.flatStructure.utf8))
        #expect(response.structure.schemaType == .flat)
        #expect(response.structure.summary.totalMidLevelNodes == nil)
        #expect(response.structure.nodes.count == 2)
        for node in response.structure.nodes {
            guard case .paragraph = node else {
                Issue.record("Expected paragraph nodes, got \(node)")
                return
            }
        }
    }

    @Test("Chapter nodes at the top level decode for standard_book")
    func decodesStandardBookChapters() throws {
        let response = try MetabookJSON.decoder.decode(BookUploadResponse.self, from: Data(Fixtures.upload.utf8))
        guard case .chapter(let chapter) = response.structure.nodes.first else {
            Issue.record("Expected a chapter node")
            return
        }
        #expect(chapter.label == "Chapter 1")
        #expect(response.blob.sizeBytes == 4096)
        #expect(response.book.isbn == "9780000000000")
        #expect(response.meta.spineDocumentCount == 3)
    }

    @Test(
        "Timestamps parse with and without fractional seconds",
        arguments: [
            "2026-09-01T02:44:30.123456Z",
            "2026-09-01T02:44:30Z",
            "2026-09-01T02:44:30.5+00:00",
        ])
    func parsesDates(raw: String) throws {
        let date = try MetabookJSON.parseDate(raw)
        let reference = try Date("2026-09-01T02:44:30Z", strategy: .iso8601)
        #expect(abs(date.timeIntervalSince(reference)) < 1)
    }

    @Test("Schema catalogue decodes every known SchemaType")
    func decodesSchemas() throws {
        let schemas = try MetabookJSON.decoder.decode([SchemaInfo].self, from: Data(Fixtures.schemas.utf8))
        #expect(Set(schemas.map(\.name)) == Set(SchemaType.allCases))
    }

    @Test("Structure round-trips through the encoder")
    func roundTrips() throws {
        let original = try MetabookJSON.decoder.decode(BookStructureResponse.self, from: Data(Fixtures.structure.utf8))
        let data = try MetabookJSON.encoder.encode(original)
        let decoded = try MetabookJSON.decoder.decode(BookStructureResponse.self, from: data)
        #expect(decoded.structure == original.structure)
        #expect(decoded.book == original.book)
    }
}
