// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SmartCodablePublicAPISmoke",
    platforms: [.macOS(.v10_15)],
    dependencies: [.package(name: "SmartCodable", path: "../..")],
    targets: [
        .executableTarget(
            name: "PublicAPISmoke",
            dependencies: [.product(name: "SmartCodable", package: "SmartCodable")]
        )
    ]
)
