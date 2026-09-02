import Foundation

/// Build-time facts about this copy of the SDK.
public enum MetabookSDKInfo {
    /// The package version, kept in sync with the `VERSION` file by the release pipeline.
    public static let version = "0.0.0"

    /// The `User-Agent` fragment the client sends.
    public static let userAgent = "MetabookSDK/\(version)"
}
