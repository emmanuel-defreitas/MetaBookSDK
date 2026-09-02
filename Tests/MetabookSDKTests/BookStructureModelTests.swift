import Foundation
import Testing

@testable import MetabookSDK

@Suite("BookStructureModel")
@MainActor
struct BookStructureModelTests {
    private func model(_ transport: MockTransport) -> BookStructureModel {
        let client = MetabookClient(
            configuration: MetabookConfiguration(baseURL: URL(string: "https://metabook.example.com")!),
            transport: transport
        )
        return BookStructureModel(client: client)
    }

    @Test("Successful lookup lands in .loaded and exposes the structure")
    func loads() async {
        let model = model(MockTransport(json: Fixtures.structure))
        await model.load(.gutenbergId(1342))
        #expect(model.lookup.response?.book.title == "Pride and Prejudice")
        #expect(model.structure?.schemaType == .sectionedBook)
        #expect(model.lookup.isLoading == false)
    }

    @Test("Ambiguous lookup lands in .ambiguous and select() resolves it")
    func ambiguousThenSelect() async {
        let model = model(MockTransport(status: 300, json: Fixtures.disambiguation))
        await model.load(.title("Pride"))
        #expect(model.lookup.matches.count == 2)

        let resolved = self.model(MockTransport(json: Fixtures.structure))
        await resolved.select(BookMatch(gutenbergId: 1342, title: "Pride and Prejudice"))
        #expect(resolved.lookup.response != nil)
    }

    @Test("Failures land in .failed with a typed error")
    func fails() async {
        let model = model(MockTransport(status: 404, json: #"{"detail": {"error": "book_not_found"}}"#))
        await model.load(.title("Nothing"))
        guard case .bookNotFound = model.lookup.error else {
            Issue.record("Expected bookNotFound, got \(String(describing: model.lookup.error))")
            return
        }
    }

    @Test("Upload lands in .loaded and structure prefers the upload result")
    func uploads() async {
        let model = model(MockTransport(status: 201, json: Fixtures.upload))
        await model.upload(epub: Data(), filename: "a.epub")
        #expect(model.upload.response?.book.title == "My Book")
        #expect(model.structure?.schemaType == .standardBook)
    }

    @Test("reset() returns both states to idle")
    func resets() async {
        let model = model(MockTransport(json: Fixtures.structure))
        await model.load(.gutenbergId(1))
        model.reset()
        guard case .idle = model.lookup, case .idle = model.upload else {
            Issue.record("Expected idle states")
            return
        }
    }
}
