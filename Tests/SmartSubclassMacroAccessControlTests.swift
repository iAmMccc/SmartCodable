import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import SmartCodableMacros

/// Tests for `@SmartSubclass` macro access control inference.
///
/// These tests verify that the macro correctly derives access modifiers for
/// synthesized members (`init(from:)`, `encode(to:)`, `init()`) based on the
/// visibility of the host class.
final class SmartSubclassMacroAccessControlTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "SmartSubclass": SmartSubclassMacro.self
    ]

    // MARK: - Helpers

    /// Base model definition shared across all test cases.
    private let baseModelDefinition = """
        class BaseModel {
            var name: String = ""

            required init() {}
            required init(from decoder: Decoder) throws {}
            func encode(to encoder: Encoder) throws {}
        }
        """

    /// Asserts macro expansion with consistent base model context.
    ///
    /// - Parameters:
    ///   - classDeclaration: The subclass declaration with `@SmartSubclass` attribute.
    ///   - expectedClassOutput: The expected expanded source code.
    ///   - file: Source file for failure reporting.
    ///   - line: Line number for failure reporting.
    private func assertAccessControlMacroExpansion(
        classDeclaration: String,
        expectedClassOutput: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let input = """
            \(baseModelDefinition)

            @SmartSubclass
            \(classDeclaration)
            """

        let expectedOutput = """
            \(baseModelDefinition)
            \(expectedClassOutput)
            """

        assertMacroExpansion(
            input,
            expandedSource: expectedOutput,
            macros: macros,
            file: file,
            line: line
        )
    }

    // MARK: - Tests

    /// Verifies that `public` class generates members with `public` modifiers.
    func testPublicClassExpansionAddsPublicAccessModifiers() {
        assertAccessControlMacroExpansion(
            classDeclaration: """
                public class PublicStudent: BaseModel {
                    var age: Int = 0
                }
                """,
            expectedClassOutput: """
                public class PublicStudent: BaseModel {
                    var age: Int = 0

                    enum CodingKeys: CodingKey {
                        case age
                    }

                    public required init(from decoder: Decoder) throws {
                        try super.init(from: decoder)

                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.age = try container.decodeIfPresent(Int.self, forKey: .age) ?? self.age
                    }

                    public override func encode(to encoder: Encoder) throws {
                        try super.encode(to: encoder)

                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(age, forKey: .age)
                    }

                    public required init() {
                        super.init()
                    }
                }
                """
        )
    }

    /// Verifies that `open` class generates members with `public` modifiers (Phase 1).
    func testOpenClassExpansionAddsPublicAccessModifiers() {
        assertAccessControlMacroExpansion(
            classDeclaration: """
                open class OpenStudent: BaseModel {
                    var age: Int = 0
                }
                """,
            expectedClassOutput: """
                open class OpenStudent: BaseModel {
                    var age: Int = 0

                    enum CodingKeys: CodingKey {
                        case age
                    }

                    public required init(from decoder: Decoder) throws {
                        try super.init(from: decoder)

                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.age = try container.decodeIfPresent(Int.self, forKey: .age) ?? self.age
                    }

                    public override func encode(to encoder: Encoder) throws {
                        try super.encode(to: encoder)

                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(age, forKey: .age)
                    }

                    public required init() {
                        super.init()
                    }
                }
                """
        )
    }

    /// Verifies that internal/default class does not add explicit `public` modifiers.
    func testInternalClassDoesNotAddPublicAccessModifiers() {
        assertAccessControlMacroExpansion(
            classDeclaration: """
                class InternalStudent: BaseModel {
                    var age: Int = 0
                }
                """,
            expectedClassOutput: """
                class InternalStudent: BaseModel {
                    var age: Int = 0

                    enum CodingKeys: CodingKey {
                        case age
                    }

                    required init(from decoder: Decoder) throws {
                        try super.init(from: decoder)

                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.age = try container.decodeIfPresent(Int.self, forKey: .age) ?? self.age
                    }

                    override func encode(to encoder: Encoder) throws {
                        try super.encode(to: encoder)

                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(age, forKey: .age)
                    }

                    required init() {
                        super.init()
                    }
                }
                """
        )
    }

    /// Verifies that existing `required init()` prevents duplicate generation.
    func testClassWithExistingRequiredInitSkipsGeneratedInit() {
        assertAccessControlMacroExpansion(
            classDeclaration: """
                public class StudentWithInit: BaseModel {
                    var age: Int = 0

                    required init() {
                        super.init()
                    }
                }
                """,
            expectedClassOutput: """
                public class StudentWithInit: BaseModel {
                    var age: Int = 0

                    required init() {
                        super.init()
                    }

                    enum CodingKeys: CodingKey {
                        case age
                    }

                    public required init(from decoder: Decoder) throws {
                        try super.init(from: decoder)

                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.age = try container.decodeIfPresent(Int.self, forKey: .age) ?? self.age
                    }

                    public override func encode(to encoder: Encoder) throws {
                        try super.encode(to: encoder)

                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(age, forKey: .age)
                    }
                }
                """
        )
    }
}
