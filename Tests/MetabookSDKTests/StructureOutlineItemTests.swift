import Foundation
import Testing

@testable import MetabookSDK

@Suite("StructureOutlineItem")
struct StructureOutlineItemTests {
    @Test("Outline mirrors the tree and produces unique ids across depths")
    func buildsOutline() throws {
        let response = try MetabookJSON.decoder.decode(BookStructureResponse.self, from: Data(Fixtures.structure.utf8))
        let items = StructureOutlineItem.items(for: response.structure)

        #expect(items.count == 1)
        let volume = try #require(items.first)
        #expect(volume.title == "Volume I")
        #expect(volume.children?.count == 2)

        let chapterOne = try #require(volume.children?.first)
        #expect(chapterOne.children?.count == 1)
        let chapterTwo = try #require(volume.children?.last)
        #expect(chapterTwo.children == nil)

        var ids = Set<String>()
        func collect(_ item: StructureOutlineItem) {
            ids.insert(item.id)
            item.children?.forEach(collect)
        }
        items.forEach(collect)
        #expect(ids.count == 4)
    }

    @Test("Paragraph rows synthesise a one-based label")
    func paragraphLabel() {
        let node = StructureNode.paragraph(
            ParagraphNode(index: 2, sentenceCount: 1, wordCount: 1, avgWordsPerSentence: 1))
        #expect(node.label == "Paragraph 3")
    }
}
