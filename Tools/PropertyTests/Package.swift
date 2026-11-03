// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "SmartCodablePropertyTests",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(name: "SmartCodable", path: "../.."),
        .package(url: "https://github.com/x-sheep/swift-property-based.git", exact: "2.0.1")
    ],
    targets: [
        .testTarget(
            name: "PropertyTests",
            dependencies: [
                .product(name: "SmartCodable", package: "SmartCodable"),
                .product(name: "PropertyBased", package: "swift-property-based")
            ]
        )
    ]
)
