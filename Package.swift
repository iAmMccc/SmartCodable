// swift-tools-version: 5.9
import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "SmartCodable",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13), .visionOS(.v1)],
    products: [
        // Core library without macro support (no swift-syntax dependency)
        // Recommended for users who don't need inheritance features
        .library(
            name: "SmartCodable",
            targets: ["SmartCodable"]
        ),
        // Full library with macro support (includes swift-syntax dependency)
        // Use this if you need @SmartSubclass and inheritance features
        .library(
            name: "SmartCodableWithMacros",
            targets: ["SmartCodable", "SmartCodableInherit"]
        ),
        // Legacy product name for backward compatibility
        // Deprecated: Use SmartCodableWithMacros instead
        .library(
            name: "SmartCodableInherit",
            targets: ["SmartCodableInherit"]
        )
    ],
    dependencies: [
        // Depend on the Swift 5.9+ SwiftSyntax for macro support
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "509.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "SmartCodableMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(
            name: "SmartCodable",
            exclude: ["MacroSupport"]),
        
        .target(
            name: "SmartCodableInherit",
            dependencies: [
                "SmartCodableMacros"
            ],
            path: "Sources/SmartCodable/MacroSupport"),
        
        // A test target used to develop the macro implementation.
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
