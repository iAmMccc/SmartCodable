import XCTest
import SmartCodableInherit
@testable import SmartCodable

/// @SmartSubclass 宏集成测试：验证继承场景下编解码的端到端行为
final class SmartSubclassIntegrationTests: XCTestCase {
    /// 父类 + 子类字段都能正确解码和编码
    func testSmartSubclassDecodeEncodeKeepsInheritedAndSubclassFields() {
        let dict: [String: Any] = [
            "name": "Linus",
            "age": 35,
        ]

        let model = SmartSubclassModel.deserialize(from: dict)

        XCTAssertEqual(model?.name, "Linus")
        XCTAssertEqual(model?.age, 35)
        XCTAssertEqual(model?.toDictionary()?["name"] as? String, "Linus")
        XCTAssertEqual(model?.toDictionary()?["age"] as? Int, 35)
    }

    /// lazy 属性不参与编解码，保持计算语义
    func testSmartSubclassSkipsLazyPropertyDuringDecodeAndEncode() {
        let dict: [String: Any] = [
            "name": "Ada",
            "age": 22,
            "desc": "should-be-ignored",
        ]

        let model = SmartSubclassModel.deserialize(from: dict)

        XCTAssertEqual(model?.desc, "我的名字是Ada")
        XCTAssertNil(model?.toDictionary()?["desc"])
    }

    /// 宏自动生成的 required init() 使用属性默认值
    func testSmartSubclassGeneratesRequiredInit() {
        let model = SmartSubclassModel()
        XCTAssertEqual(model.name, "")
        XCTAssertEqual(model.age, 0)
    }

    /// 多层继承（祖父→父→子）所有层级字段均正确编解码
    func testSmartSubclassMultiLevelInheritanceKeepsAllFields() {
        let dict: [String: Any] = [
            "name": "Grace",
            "height": 170,
            "age": 30,
        ]

        let model = SmartSubclassMultiLevelModel.deserialize(from: dict)

        XCTAssertEqual(model?.name, "Grace")
        XCTAssertEqual(model?.height, 170)
        XCTAssertEqual(model?.age, 30)
        XCTAssertEqual(model?.toDictionary()?["name"] as? String, "Grace")
        XCTAssertEqual(model?.toDictionary()?["height"] as? Int, 170)
        XCTAssertEqual(model?.toDictionary()?["age"] as? Int, 30)
    }

    /// 缺失字段使用默认值，不崩溃
    func testSmartSubclassMissingKeysKeepsDefaults() {
        let model = SmartSubclassModel.deserialize(from: ["name": "Linus"])
        XCTAssertEqual(model?.name, "Linus")
        XCTAssertEqual(model?.age, 0)
    }

    /// @propertyWrapper 包裹的属性在继承链中正常编解码
    func testSmartSubclassPropertyWrapperBackedStorageEncodesAndDecodes() {
        let dict: [String: Any] = [
            "name": "Alan",
            "age": 42,
        ]

        let model = WrappedSubModel.deserialize(from: dict)

        XCTAssertEqual(model?.name, "Alan")
        XCTAssertEqual(model?.age, 42)
        XCTAssertEqual(model?.toDictionary()?["name"] as? String, "Alan")
        XCTAssertEqual(model?.toDictionary()?["age"] as? Int, 42)
    }

    /// 手动提供 required init() 时宏不重复生成
    func testSmartSubclassDoesNotDuplicateRequiredInitWhenProvided() {
        let model = SmartSubclassModelWithCustomRequiredInit()
        XCTAssertEqual(model.name, "")
        XCTAssertEqual(model.age, 7)
    }
}
