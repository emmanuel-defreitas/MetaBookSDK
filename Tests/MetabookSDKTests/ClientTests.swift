import Foundation
import Testing

@testable import MetabookSDK

@Suite("MetabookClient")
struct ClientTests {
    private let base = URL(string: "https://metabook.example.com")!

    private func client(_ transport: MockTransport) -> MetabookClient {
        MetabookClient(
            configuration: MetabookConfiguration(baseURL: base, additionalHeaders: ["X-Token": "abc"]),
            transport: transport
        )
    }

    @Test("Title lookup builds the documented query string")
    func buildsStructureRequest() async throws {
        let transport = MockTransport(json: Fixtures.structure)
        let options = StructureOptions(language: "fr", includeParagraphs: false, detail: .clause)
        _ = try await client(transport).structure(for: .title("Pride and Prejudice"), options: options)

        let request = try #require(transport.lastRequest)
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == "/api/books/structure")
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        #expect(
            items == [
                "title": "Pride and Prejudice",
                "language": "fr",
                "include_paragraphs": "false",
                "detail": "clause",
            ])
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "X-Token") == "abc")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("Gutenberg ID and ISBN queries use their own parameter names")
    func queryParameterNames() {
        #expect(BookQuery.gutenbergId(1342).queryItems == [URLQueryItem(name: "gutenberg_id", value: "1342")])
        #expect(BookQuery.isbn("978").queryItems == [URLQueryItem(name: "isbn", value: "978")])
    }

    @Test("A base URL with a path prefix is preserved")
    func preservesBasePath() throws {
        let prefixed = MetabookClient(
            configuration: MetabookConfiguration(baseURL: URL(string: "https://host/metabook/")!),
            transport: MockTransport()
        )
        let request = try prefixed.makeRequest(path: "/health", queryItems: [])
        #expect(request.url?.absoluteString == "https://host/metabook/health")
    }

    @Test("HTTP 300 surfaces as an ambiguous lookup, not an error")
    func ambiguousLookup() async throws {
        let transport = MockTransport(status: 300, json: Fixtures.disambiguation)
        let result = try await client(transport).structure(for: .title("Pride"))
        #expect(result.response == nil)
        #expect(result.matches.map(\.gutenbergId) == [1342, 42671])
    }

    @Test(
        "Error statuses map to typed errors",
        arguments: [
            (404, #"{"detail": {"error": "book_not_found", "query": {}}}"#, "bookNotFound"),
            (422, #"{"detail": {"error": "text_unavailable", "gutenberg_id": 9}}"#, "textUnavailable"),
            (422, #"{"detail": {"error": "invalid_detail", "allowed": ["paragraph"]}}"#, "invalidRequest"),
            (422, #"{"detail": "At least one of 'title', 'isbn', or 'gutenberg_id' is required."}"#, "invalidRequest"),
            (502, #"{"detail": {"error": "gutendex_unreachable", "message": "boom"}}"#, "gutendexUnavailable"),
            (504, #"{"detail": {"error": "gutendex_unreachable", "message": "slow"}}"#, "gutendexTimeout"),
            (500, "oops", "unexpectedStatus"),
        ])
    func mapsStructureErrors(status: Int, body: String, expected: String) async {
        let transport = MockTransport(status: status, json: body)
        do {
            _ = try await client(transport).structure(for: .title("x"))
            Issue.record("Expected an error")
        } catch let error as MetabookError {
            switch (error, expected) {
            case (.bookNotFound, "bookNotFound"): break
            case (.textUnavailable(let id), "textUnavailable"): #expect(id == 9)
            case (.invalidRequest, "invalidRequest"): break
            case (.gutendexUnavailable(let message, false), "gutendexUnavailable"): #expect(message == "boom")
            case (.gutendexUnavailable(let message, true), "gutendexTimeout"): #expect(message == "slow")
            case (.unexpectedStatus(let code, let text), "unexpectedStatus"):
                #expect(code == 500)
                #expect(text == "oops")
            default: Issue.record("Got \(error), expected \(expected)")
            }
        } catch {
            Issue.record("Unexpected error type \(error)")
        }
    }

    @Test("Upload posts multipart form data and decodes a 201")
    func uploadsEpub() async throws {
        let transport = MockTransport(status: 201, json: Fixtures.upload)
        let bytes = Data("PK\u{03}\u{04}fake".utf8)
        let response = try await client(transport).upload(
            epub: bytes, filename: "my-book.epub", options: StructureOptions(detail: .word))

        #expect(response.book.title == "My Book")
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/api/books/upload")
        #expect(request.url?.query?.contains("detail=word") == true)
        #expect(request.url?.query?.contains("language=") == false)

        let contentType = try #require(request.value(forHTTPHeaderField: "Content-Type"))
        #expect(contentType.hasPrefix("multipart/form-data; boundary="))
        let boundary = contentType.replacing("multipart/form-data; boundary=", with: "")
        let body = String(decoding: try #require(request.httpBody), as: UTF8.self)
        #expect(body.hasPrefix("--\(boundary)\r\n"))
        #expect(body.contains(#"Content-Disposition: form-data; name="file"; filename="my-book.epub""#))
        #expect(body.contains("Content-Type: application/epub+zip"))
        #expect(body.contains("PK\u{03}\u{04}fake"))
        #expect(body.hasSuffix("--\(boundary)--\r\n"))
    }

    @Test(
        "Upload error statuses map to typed errors",
        arguments: [
            (400, #"{"detail": {"error": "invalid_epub", "message": "no spine"}}"#, "invalidEpub"),
            (413, #"{"detail": {"error": "file_too_large", "max_bytes": 1024}}"#, "fileTooLarge"),
            (502, #"{"detail": {"error": "blob_upload_failed", "message": "token"}}"#, "blobUploadFailed"),
        ])
    func mapsUploadErrors(status: Int, body: String, expected: String) async {
        let transport = MockTransport(status: status, json: body)
        do {
            _ = try await client(transport).upload(epub: Data(), filename: "a.epub")
            Issue.record("Expected an error")
        } catch let error as MetabookError {
            switch (error, expected) {
            case (.invalidEpub(let message), "invalidEpub"): #expect(message == "no spine")
            case (.fileTooLarge(let max), "fileTooLarge"): #expect(max == 1024)
            case (.blobUploadFailed(let message), "blobUploadFailed"): #expect(message == "token")
            default: Issue.record("Got \(error), expected \(expected)")
            }
        } catch {
            Issue.record("Unexpected error type \(error)")
        }
    }

    @Test("Schemas and health decode from their endpoints")
    func schemasAndHealth() async throws {
        let schemas = try await client(MockTransport(json: Fixtures.schemas)).schemas()
        #expect(schemas.count == 5)

        let healthTransport = MockTransport(json: Fixtures.health)
        let health = try await client(healthTransport).health()
        #expect(health.isHealthy)
        #expect(health.cacheEntries == 4)
        #expect(healthTransport.lastRequest?.url?.path == "/health")
    }

    @Test("Transport failures are wrapped")
    func wrapsTransportErrors() async {
        struct Failing: MetabookTransport {
            func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
                throw URLError(.notConnectedToInternet)
            }
        }
        let client = MetabookClient(configuration: MetabookConfiguration(baseURL: base), transport: Failing())
        do {
            _ = try await client.health()
            Issue.record("Expected an error")
        } catch let MetabookError.transport(inner) {
            #expect((inner as? URLError)?.code == .notConnectedToInternet)
        } catch {
            Issue.record("Unexpected error \(error)")
        }
    }
}
