import Foundation

/// Async client for the metabook-py REST API. Value type, `Sendable`, and safe to share across tasks.
///
/// ```swift
/// let client = MetabookClient(configuration: .localhost)
/// switch try await client.structure(for: .title("Pride and Prejudice")) {
/// case .found(let response): print(response.structure.schemaType)
/// case .ambiguous(let result): print(result.matches)
/// }
/// ```
public struct MetabookClient: Sendable {
    public var configuration: MetabookConfiguration
    public var transport: any MetabookTransport

    public init(
        configuration: MetabookConfiguration = .localhost,
        transport: any MetabookTransport = URLSessionTransport()
    ) {
        self.configuration = configuration
        self.transport = transport
    }

    // MARK: - Endpoints

    /// `GET /api/books/structure`. Returns ``StructureLookup/ambiguous(_:)`` on HTTP 300 rather than throwing.
    public func structure(
        for query: BookQuery,
        options: StructureOptions = .default
    ) async throws -> StructureLookup {
        var request = try makeRequest(
            path: "/api/books/structure",
            queryItems: query.queryItems + options.queryItems(includingLanguage: true)
        )
        request.httpMethod = "GET"

        let (data, response) = try await perform(request)
        switch response.statusCode {
        case 200:
            return .found(try decode(BookStructureResponse.self, from: data))
        case 300:
            return .ambiguous(try decode(DisambiguationResult.self, from: data))
        default:
            throw mapStructureError(status: response.statusCode, data: data, query: query)
        }
    }

    /// `GET /api/books/structure/schemas`.
    public func schemas() async throws -> [SchemaInfo] {
        var request = try makeRequest(path: "/api/books/structure/schemas", queryItems: [])
        request.httpMethod = "GET"
        let (data, response) = try await perform(request)
        guard response.statusCode == 200 else {
            throw genericError(status: response.statusCode, data: data)
        }
        return try decode([SchemaInfo].self, from: data)
    }

    /// `POST /api/books/upload` with in-memory EPUB bytes.
    public func upload(
        epub data: Data,
        filename: String,
        options: StructureOptions = .default
    ) async throws -> BookUploadResponse {
        var request = try makeRequest(
            path: "/api/books/upload",
            queryItems: options.queryItems(includingLanguage: false)
        )
        request.httpMethod = "POST"

        var form = MultipartFormData()
        form.addFile(name: "file", filename: filename, mimeType: "application/epub+zip", data: data)
        request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = form.finalized()

        let (body, response) = try await perform(request)
        switch response.statusCode {
        case 200, 201:
            return try decode(BookUploadResponse.self, from: body)
        default:
            throw mapUploadError(status: response.statusCode, data: body)
        }
    }

    /// `POST /api/books/upload`, reading the EPUB from a file URL. Handles security-scoped access
    /// for URLs obtained from a file importer.
    public func upload(
        epubAt fileURL: URL,
        options: StructureOptions = .default
    ) async throws -> BookUploadResponse {
        let scoped = fileURL.startAccessingSecurityScopedResource()
        defer { if scoped { fileURL.stopAccessingSecurityScopedResource() } }
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw MetabookError.transport(error)
        }
        return try await upload(epub: data, filename: fileURL.lastPathComponent, options: options)
    }

    /// `GET /health`.
    public func health() async throws -> HealthStatus {
        var request = try makeRequest(path: "/health", queryItems: [])
        request.httpMethod = "GET"
        let (data, response) = try await perform(request)
        guard response.statusCode == 200 else {
            throw genericError(status: response.statusCode, data: data)
        }
        return try decode(HealthStatus.self, from: data)
    }

    // MARK: - Request plumbing

    func makeRequest(path: String, queryItems: [URLQueryItem]) throws -> URLRequest {
        guard var components = URLComponents(url: configuration.baseURL, resolvingAgainstBaseURL: false) else {
            throw MetabookError.transport(URLError(.badURL))
        }
        let basePath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        components.path = basePath + path
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else {
            throw MetabookError.transport(URLError(.badURL))
        }

        var request = URLRequest(url: url, timeoutInterval: configuration.timeout)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(MetabookSDKInfo.userAgent, forHTTPHeaderField: "User-Agent")
        for (field, value) in configuration.additionalHeaders {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            return try await transport.send(request)
        } catch let error as MetabookError {
            throw error
        } catch {
            throw MetabookError.transport(error)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try MetabookJSON.decoder.decode(type, from: data)
        } catch {
            throw MetabookError.decoding(error)
        }
    }

    // MARK: - Error mapping

    private func mapStructureError(status: Int, data: Data, query: BookQuery) -> MetabookError {
        let body = APIErrorBody.parse(data)
        switch (status, body?.code) {
        case (404, _):
            return .bookNotFound(query)
        case (422, "text_unavailable"):
            return .textUnavailable(gutenbergId: body?.gutenbergId)
        case (422, "invalid_detail"):
            let allowed =
                body?.allowed?.joined(separator: ", ") ?? DetailLevel.allCases.map(\.rawValue).joined(separator: ", ")
            return .invalidRequest(message: "Invalid detail level. Allowed: \(allowed).")
        case (422, _):
            return .invalidRequest(message: body?.message ?? "The request was rejected.")
        case (502, _), (504, _):
            return .gutendexUnavailable(message: body?.message ?? "no details", timedOut: status == 504)
        default:
            return genericError(status: status, data: data, parsed: body)
        }
    }

    private func mapUploadError(status: Int, data: Data) -> MetabookError {
        let body = APIErrorBody.parse(data)
        switch (status, body?.code) {
        case (400, _):
            return .invalidEpub(message: body?.message ?? "Only .epub files are accepted.")
        case (413, _):
            return .fileTooLarge(maxBytes: body?.maxBytes)
        case (422, _):
            return .invalidRequest(message: body?.message ?? "The request was rejected.")
        case (502, _):
            return .blobUploadFailed(message: body?.message ?? "no details")
        default:
            return genericError(status: status, data: data, parsed: body)
        }
    }

    private func genericError(status: Int, data: Data, parsed: APIErrorBody? = nil) -> MetabookError {
        let text = parsed?.message ?? String(decoding: data, as: UTF8.self)
        return .unexpectedStatus(code: status, body: text)
    }
}
