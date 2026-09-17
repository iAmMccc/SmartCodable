import XCTest
@testable import SmartCodable

/// @SmartFlat 快照污染：Flat 属性声明在前时，后续属性默认值 / 包装器 / mappingForValue 被污染
final class SmartFlatTests: XCTestCase {

    /// @SmartFlat 之后的普通属性：JSON 缺 key 时应保留模型默认值，而不是类型零值
    func testSmartFlatBeforePlainPropertiesKeepsCustomDefaultsWhenKeysMissing() {
        struct Model: SmartCodableX {
            @SmartFlat var user: FlatUser?
            var mikeNo: String = "我是默认值"
            var num: Int = 999
        }

        let model = Model.deserialize(from: ["accid": "a1"])

        XCTAssertNotNil(model)
        XCTAssertEqual(model?.user?.accid, "a1")
        XCTAssertEqual(model?.mikeNo, "我是默认值")
        XCTAssertEqual(model?.num, 999)
    }

    /// @SmartFlat 之后跟 @SmartIgnored：整模型应成功解码，而不是返回 nil
    func testSmartFlatBeforeSmartIgnoredStillDeserializesModel() {
        struct Model: SmartCodableX {
            @SmartFlat var user: FlatUser?
            var mikeNo: String = "我是默认值"
            var num: Int = 999
            @SmartIgnored var extra: Bool = true
        }

        let model = Model.deserialize(from: ["accid": "a1"])

        XCTAssertNotNil(model)
        XCTAssertEqual(model?.user?.accid, "a1")
        XCTAssertEqual(model?.mikeNo, "我是默认值")
        XCTAssertEqual(model?.num, 999)
        XCTAssertEqual(model?.extra, true)
    }

    /// @SmartFlat 之后带 mappingForValue 的属性：自定义转换器应生效
    func testSmartFlatBeforeMappingForValueAppliesTransformer() {
        struct Model: SmartCodableX {
            @SmartFlat var user: FlatUser?
            var name: String = ""

            static func mappingForValue() -> [SmartValueTransformer]? {
                [CodingKeys.name <--- UpperTransformer()]
            }
        }

        let model = Model.deserialize(from: ["accid": "a1", "name": "mccc"])

        XCTAssertNotNil(model)
        XCTAssertEqual(model?.user?.accid, "a1")
        XCTAssertEqual(model?.name, "MCCC")
    }

    /// @SmartFlat 之后的枚举：JSON 缺 key 时应保留声明的默认 case
    func testSmartFlatBeforeEnumKeepsDeclaredDefaultCaseWhenKeyMissing() throws {
        struct Model: SmartCodableX {
            @SmartFlat var user: FlatUser?
            var kind: FlatDefaultKind = .preferred
        }

        let model = try XCTUnwrap(Model.deserialize(from: ["accid": "a1"]))

        XCTAssertEqual(model.user?.accid, "a1")
        XCTAssertEqual(model.kind, .preferred)
    }

    /// @SmartFlat 之后跟包装模型的 @SmartIgnored：应保留包装模型的默认值
    func testSmartFlatBeforeModelBackedSmartIgnoredStillDeserializesModel() throws {
        struct Model: SmartCodableX {
            @SmartFlat var user: FlatUser?
            @SmartIgnored var settings: IgnoredSettings = .init()
        }

        let model = try XCTUnwrap(Model.deserialize(from: ["accid": "a1"]))

        XCTAssertEqual(model.user?.accid, "a1")
        XCTAssertTrue(model.settings.isEnabled)
    }

    /// @SmartFlat 之后跟 @SmartAny：应保留动态属性的默认值
    func testSmartFlatBeforeSmartAnyStillDeserializesModel() throws {
        struct Model: SmartCodableX {
            @SmartFlat var user: FlatUser?
            @SmartAny var metadata: [String: Any] = ["source": "default"]
        }

        let model = try XCTUnwrap(Model.deserialize(from: ["accid": "a1"]))

        XCTAssertEqual(model.user?.accid, "a1")
        XCTAssertEqual(model.metadata["source"] as? String, "default")
    }

    /// 含 @SmartFlat 污染场景的模型作为数组元素时，应保留每个元素解码出的数据
    func testSmartFlatSnapshotPreservesArrayElementValues() throws {
        struct Model: SmartCodableX {
            @SmartFlat var user: FlatUser?
            @SmartIgnored var extra: Bool = true
        }

        let models = try XCTUnwrap([Model].deserialize(from: [
            ["accid": "a1"],
            ["accid": "a2"],
        ]))

        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(models.compactMap(\.user?.accid), ["a1", "a2"])
        XCTAssertTrue(models.allSatisfy(\.extra))
    }

    /// @SmartFlat 之前的属性不受后续平铺解码影响
    func testPropertyBeforeSmartFlatKeepsDeclaredDefaultWhenKeyMissing() throws {
        struct Model: SmartCodableX {
            var title: String = "默认标题"
            @SmartFlat var user: FlatUser?
        }

        let model = try XCTUnwrap(Model.deserialize(from: ["accid": "a1"]))

        XCTAssertEqual(model.title, "默认标题")
        XCTAssertEqual(model.user?.accid, "a1")
    }

    /// @SmartFlat 包装非 Optional 模型：内层字段缺 key 时应保留内层声明的默认值，
    /// 而不是退化为类型零值（内层模型不经 unwrap 直接初始化的路径）
    func testNonOptionalSmartFlatKeepsInnerModelDefaultsWhenKeysMissing() throws {
        struct Model: SmartCodableX {
            @SmartFlat var user: NonOptionalFlatUser = NonOptionalFlatUser()
            var tail: Int = 3
        }

        let model = try XCTUnwrap(Model.deserialize(from: ["accid": "a1"]))

        XCTAssertEqual(model.user.accid, "a1")
        XCTAssertEqual(model.user.level, 42)
        XCTAssertEqual(model.tail, 3)
    }
}

/// 被 @SmartFlat 平铺的内层模型（issue 最小复现）
private final class FlatUser: SmartCodableX {
    var accid: String = ""
    required init() {}
}

/// 非 Optional 形式的平铺内层模型（默认值与类型零值不同，用于断言敏感度）
private final class NonOptionalFlatUser: SmartCodableX {
    var accid: String = ""
    var level: Int = 42
    required init() {}
}

/// 用于验证枚举默认值不会退化为首个 case
private enum FlatDefaultKind: Int, SmartCaseDefaultable {
    case fallback
    case preferred
}

/// 用于验证 @SmartIgnored 包装 SmartDecodable 模型的路径
private struct IgnoredSettings: SmartCodableX {
    var isEnabled: Bool = true
}

/// 将字符串转为大写的转换器（用于验证 mappingForValue）
private struct UpperTransformer: ValueTransformable {
    typealias Object = String
    typealias JSON = String

    func transformFromJSON(_ value: Any) -> String? {
        (value as? String)?.uppercased()
    }

    func transformToJSON(_ value: String) -> String? {
        value
    }
}
