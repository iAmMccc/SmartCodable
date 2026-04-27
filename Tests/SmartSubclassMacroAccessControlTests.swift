import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import SmartCodableMacros

/// @SmartSubclass 宏访问控制测试：验证宏根据宿主类可见性生成匹配的访问修饰符
final class SmartSubclassMacroAccessControlTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "SmartSubclass": SmartSubclassMacro.self
    ]

    // MARK: - Helpers

    /// 共享的父类定义模板
    private let baseModelDefinition = """
        class BaseModel {
            var name: String = ""

            required init() {}
            required init(from decoder: Decoder) throws {}
            func encode(to encoder: Encoder) throws {}
        }
        """

    /// 统一断言宏展开结果（自动拼接父类上下文）
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

    /// public 类 → 生成的 init(from:)、encode(to:)、init() 均带 public
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

    /// open 类 → 生成的成员使用 public（非 open，因为无法跨模块 override）
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

    /// internal（默认）类 → 生成的成员不加显式访问修饰符
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

    /// 已有 required init() 时宏跳过生成，不产生重复定义
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
