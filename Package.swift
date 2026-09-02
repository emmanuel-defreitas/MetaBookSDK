// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MetabookSDK",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "MetabookSDK", targets: ["MetabookSDK"])
    ],
    targets: [
        .target(
            name: "MetabookSDK",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "MetabookSDKTests",
            dependencies: ["MetabookSDK"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
