// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TimeLabels",
    platforms: [
        // `platforms` declares the minimum OS version each family can use, so
        // SwiftPM gives a clear error if a consumer's deployment target is too old.
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "TimeLabels",
            targets: ["TimeLabels"]
        )
    ],
    targets: [
        .target(name: "TimeLabels"),
        .testTarget(
            name: "TimeLabelsTests",
            dependencies: ["TimeLabels"]
        )
    ]
)
