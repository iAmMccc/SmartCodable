// swift-tools-version: 6.0
import CompilerPluginSupport
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
        // 纯运行时库，不依赖宏或 SwiftSyntax
        .library(
            name: "SmartCodable",
            targets: ["SmartCodable"]
        ),

        // 带继承/宏能力，依赖 SwiftSyntax
        .library(
            name: "SmartCodableInherit",
            targets: ["SmartCodableInherit"]
        )
    ],

    dependencies: [
        // SwiftSyntax 只会被 macro target 使用
        // 注意：严格锁定版本，确保 Xcode26.3 / Swift6.1+ 可用
        .package(
            url: "https://github.com/apple/swift-syntax.git",
            from: "610.0.0"
        )
    ],

    targets: [
        // =========================
        // MARK: Runtime target (no macro)
        // =========================
        .target(
            name: "SmartCodable",
            path: "Sources/SmartCodable",
            exclude: ["MacroSupport"] // 运行时不需要 macro 文件
        ),

        // =========================
        // MARK: Macro target
        // =========================
        .macro(
            name: "SmartCodableMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax")
            ],
            path: "Sources/SmartCodableMacros"
        ),

        // =========================
        // MARK: Macro-enabled API target
        // =========================
        .target(
            name: "SmartCodableInherit",
            dependencies: [
                "SmartCodable",
                "SmartCodableMacros"
            ],
            path: "Sources/SmartCodable/MacroSupport"
        ),

        // =========================
        // MARK: Test target
        // =========================
        .testTarget(
            name: "SmartCodableTests",
            dependencies: [
                "SmartCodable",
                "SmartCodableInherit",
                "SmartCodableMacros",
                .product(
                    name: "SwiftSyntaxMacrosTestSupport",
                    package: "swift-syntax"
                )
            ],
            path: "Tests"
        )
    ]
)
