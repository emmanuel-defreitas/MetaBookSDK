import SwiftUI

extension EnvironmentValues {
    /// The client SDK views and models read by default. Override near the root of your app:
    ///
    /// ```swift
    /// ContentView()
    ///     .environment(\.metabookClient, MetabookClient(configuration: .init(baseURL: productionURL)))
    /// ```
    @Entry public var metabookClient = MetabookClient()
}

extension View {
    /// Injects a ``MetabookClient`` for every descendant.
    public func metabookClient(_ client: MetabookClient) -> some View {
        environment(\.metabookClient, client)
    }
}
