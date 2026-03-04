// swift-tools-version: 5.9
import CompilerPluginSupport
import PackageDescription

#if compiler(>=6.3)
let swiftSyntaxVersion: Version = "603.0.0"
#elseif compiler(>=6.2)
let swiftSyntaxVersion: Version = "602.0.0"
#elseif compiler(>=6.1)
let swiftSyntaxVersion: Version = "601.0.0"
#elseif compiler(>=6.0)
let swiftSyntaxVersion: Version = "600.0.0"
#elseif compiler(>=5.10)
let swiftSyntaxVersion: Version = "510.0.0"
#else
let swiftSyntaxVersion: Version = "509.0.0"
#endif

let package = Package(
    name: "SmartCodable",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13), .visionOS(.v1)],
    products: [
        .library(
            name: "SmartCodable",
            targets: ["SmartCodable"]
        ),
        .library(
            name: "SmartCodableInherit",
            targets: ["SmartCodableInherit"]
        )
    ],
    dependencies: [
        // SwiftSyntax major versions track Swift compiler versions (e.g. 602.x for Swift 6.2).
        // Pick the matching major so SwiftPM doesn't pull a macro support module built for a
        // different compiler version (which then fails to import).
        .package(url: "https://github.com/swiftlang/swift-syntax", from: swiftSyntaxVersion)
    ],
    targets: [
        .macro(
            name: "SmartCodableMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),

        .target(
            name: "SmartCodable",
            exclude: ["MacroSupport"]),

        .target(
            name: "SmartCodableInherit",
            dependencies: [
                "SmartCodableMacros"
            ],
            path: "Sources/SmartCodable/MacroSupport"),

        .testTarget(
            name: "SmartCodableTests",
            dependencies: [
                "SmartCodable",
                "SmartCodableInherit",
                "SmartCodableMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)

