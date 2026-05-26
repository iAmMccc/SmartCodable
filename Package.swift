// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SmartCodable",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "SmartCodable",
            targets: ["SmartCodable"]
        )
    ],
    targets: [
        .target(name: "SmartCodable"),
        .testTarget(
            name: "SmartCodableTests",
            dependencies: ["SmartCodable"],
            path: "Tests"
        )
    ]
)
