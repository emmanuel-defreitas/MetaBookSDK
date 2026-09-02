import Foundation
import Observation

/// Loads and caches the list of supported structural schemas.
@MainActor
@Observable
public final class SchemaCatalogModel {
    public private(set) var schemas: [SchemaInfo] = []
    public private(set) var isLoading = false
    public private(set) var error: MetabookError?

    @ObservationIgnored private let client: MetabookClient

    public init(client: MetabookClient = MetabookClient()) {
        self.client = client
    }

    /// Fetches the catalogue. Safe to call from `task()`; a second call while loaded is a no-op
    /// unless `force` is set.
    public func load(force: Bool = false) async {
        guard force || schemas.isEmpty, !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            schemas = try await client.schemas()
        } catch let error as MetabookError {
            self.error = error
        } catch {
            self.error = .transport(error)
        }
    }
}
