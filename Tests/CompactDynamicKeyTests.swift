import Foundation
import XCTest
@testable import SmartCodable

/// F-03: `@SmartCompact.Dictionary` 的数据容器在 `.recursive` 策略下必须整体走统一动态桥，
/// 数据键保持原样（不被 smartKeyEncodingStrategy 转换），与 `@SmartAny` 行为一致。
private struct F03UpperTransformer: ValueTransformable {
    typealias Object = String
    typealias JSON = String

    func transformFromJSON(_ value: Any) -> String? { (value as? String)?.uppercased() }
    func transformToJSON(_ value: String) -> String? { value.uppercased() }
}

private struct F03ChildModel: SmartCodableX {
    var userName = "child"

    static func mappingForValue() -> [SmartValueTransformer]? {
        [CodingKeys.userName <--- F03UpperTransformer()]
    }
}

private struct F03Opaque {
    let marker = 1
}

final class CompactDynamicKeyTests: XCTestCase {

    private struct DataKey: Hashable, LosslessStringConvertible {
        let description: String
        init?(_ description: String) { self.description = description }
    }

    // Distinct keys may deliberately share a textual representation. Encoding
    // keeps the existing overwrite semantics without constructing a dictionary
    // with uniqueKeysWithValues (which would trap).
    private struct AliasedKey: Hashable, LosslessStringConvertible {
        let identity: Int
        var description: String { "sharedKey" }
        init(identity: Int) { self.identity = identity }
        init?(_ description: String) {
            guard description == "sharedKey" else { return nil }
            identity = 0
        }
    }

    func testRecursiveCompactDictionaryPreservesIntegerAndCustomKeyRepresentations() throws {
        let integers = SmartCompact.Dictionary<Int, Any>(wrappedValue: [-7: "negative", 42: "positive"])
        let integerJSON = try encodedJSON(integers, recursive: true)
        XCTAssertEqual(integerJSON as? [String: String], ["-7": "negative", "42": "positive"])

        let keys = try [XCTUnwrap(DataKey("firstName")), XCTUnwrap(DataKey("first_name"))]
        let custom = SmartCompact.Dictionary<DataKey, Any>(wrappedValue: [keys[0]: 1, keys[1]: 2])
        let customJSON = try encodedJSON(custom, recursive: true)
        XCTAssertEqual(customJSON as? [String: Int], ["firstName": 1, "first_name": 2])
    }

    func testRecursiveCompactDictionaryDoesNotTrapOnDuplicateKeyDescriptions() throws {
        let value = SmartCompact.Dictionary<AliasedKey, Any>(wrappedValue: [
            AliasedKey(identity: 1): 1, AliasedKey(identity: 2): 2
        ])
        let json = try encodedJSON(value, recursive: true)
        XCTAssertEqual(Set(json.keys), ["sharedKey"])
        let survivor = try XCTUnwrap(json["sharedKey"] as? Int)
        XCTAssertTrue([1, 2].contains(survivor))
    }

    // MARK: - Helpers

    private func encodedJSON<T: Encodable>(
        _ value: T,
        recursive: Bool,
        keyStrategy: SmartJSONEncoder.SmartKeyEncodingStrategy = .toSnakeCase
    ) throws -> [String: Any] {
        let encoder = SmartJSONEncoder()
        encoder.smartDynamicValueEncodingStrategy = recursive ? .recursive : .legacy
        encoder.smartKeyEncodingStrategy = keyStrategy
        let data = try encoder.encode(value)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    // MARK: - (a) minimal counterexample

    func testRecursiveCompactDictionaryKeepsCollidingDataKeys() throws {
        struct Model: SmartCodableX {
            @SmartCompact.Dictionary var payload: [String: Any] = ["firstName": 1, "first_name": 2]
        }

        let json = try encodedJSON(Model(), recursive: true)
        let payload = try XCTUnwrap(json["payload"] as? [String: Any])
        print("F03-COUNTEREXAMPLE-RECURSIVE: " + Self.describe(payload))

        XCTAssertEqual((payload["firstName"] as? NSNumber)?.intValue, 1,
                       "observed payload: \(payload)")
        XCTAssertEqual((payload["first_name"] as? NSNumber)?.intValue, 2,
                       "observed payload: \(payload)")
        XCTAssertEqual(payload.count, 2, "observed payload: \(payload)")
    }

    // MARK: - (b) @SmartAny 与 @SmartCompact.Dictionary 的数据键矩阵一致

    func testSmartAnyAndCompactDictionaryAgreeOnRawDataKeys() throws {
        struct Model: SmartCodableX {
            @SmartAny var anyPayload: [String: Any] = [
                "firstName": 1,
                "first_name": 2,
                "nestedPayload": ["innerName": "x", "inner_name": "y"]
            ]
            @SmartCompact.Dictionary var compactPayload: [String: Any] = [
                "firstName": 1,
                "first_name": 2,
                "nestedPayload": ["innerName": "x", "inner_name": "y"]
            ]
        }

        let json = try encodedJSON(Model(), recursive: true)

        // 模型字段键仍然转换（只有数据键保持原样）
        let anyPayload = try XCTUnwrap(json["any_payload"] as? [String: Any])
        let compactPayload = try XCTUnwrap(json["compact_payload"] as? [String: Any])

        XCTAssertEqual(Set(anyPayload.keys), Set(compactPayload.keys))
        XCTAssertEqual(Set(compactPayload.keys), ["firstName", "first_name", "nestedPayload"])

        for key in ["firstName", "first_name"] {
            XCTAssertEqual((anyPayload[key] as? NSNumber)?.intValue,
                           (compactPayload[key] as? NSNumber)?.intValue)
            XCTAssertEqual((compactPayload[key] as? NSNumber)?.intValue, key == "firstName" ? 1 : 2)
        }

        // 嵌套字典的数据键同样保持原样
        let anyNested = try XCTUnwrap(anyPayload["nestedPayload"] as? [String: Any])
        let compactNested = try XCTUnwrap(compactPayload["nestedPayload"] as? [String: Any])
        print("F03-MATRIX-SMARTANY: " + Self.describe(anyPayload))
        print("F03-MATRIX-COMPACT: " + Self.describe(compactPayload))
        print("F03-MATRIX-SMARTANY-NESTED: " + Self.describe(anyNested))
        print("F03-MATRIX-COMPACT-NESTED: " + Self.describe(compactNested))
        XCTAssertEqual(Set(anyNested.keys), Set(compactNested.keys))
        XCTAssertEqual(Set(compactNested.keys), ["innerName", "inner_name"])
        XCTAssertEqual(compactNested["innerName"] as? String, "x")
        XCTAssertEqual(compactNested["inner_name"] as? String, "y")
        XCTAssertNil(compactNested["inner-name"])
    }

    // MARK: - (c) 数据容器内的模型仍执行自己的键映射与 Value Transformer

    func testNestedModelInsideDataContainerKeepsOwnKeyMappingAndTransformer() throws {
        struct Model: SmartCodableX {
            @SmartCompact.Dictionary var payload: [String: Any] = ["childModel": F03ChildModel()]
        }

        let json = try encodedJSON(Model(), recursive: true)
        let payload = try XCTUnwrap(json["payload"] as? [String: Any])

        // 数据键保持原样
        XCTAssertNotNil(payload["childModel"], "observed payload: \(payload)")
        XCTAssertNil(payload["child_model"])

        // 模型自己的字段键仍然映射 + Value Transformer 生效
        let child = try XCTUnwrap(payload["childModel"] as? [String: Any])
        XCTAssertEqual(child["user_name"] as? String, "CHILD")
        XCTAssertNil(child["userName"])
    }

    // MARK: - (d) 数据容器支持的叶子类型

    func testSupportedLeafKindsInsideDataContainer() throws {
        struct Model: SmartCodableX {
            @SmartCompact.Dictionary var payload: [String: Any] = [
                "dateValue": Date(timeIntervalSince1970: 2),
                "dataValue": Data([1, 2, 3]),
                "urlValue": URL(string: "https://example.com/a")!,
                "intValue": 7,
                "doubleValue": 1.5,
                "boolValue": true,
                "stringValue": "text",
                "nullValue": NSNull(),
                "nestedDict": ["innerKey": "innerValue"],
                "nestedArray": [1, "two", true],
                "nestedModel": F03ChildModel(),
                "optionalValue": Optional(3) as Any,
                "nilOptionalValue": Optional<Int>.none as Any
            ]
        }

        let encoder = SmartJSONEncoder()
        encoder.smartDynamicValueEncodingStrategy = .recursive
        encoder.smartKeyEncodingStrategy = .toSnakeCase
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let data = try encoder.encode(Model())
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let payload = try XCTUnwrap(json["payload"] as? [String: Any])

        XCTAssertEqual((payload["dateValue"] as? NSNumber)?.doubleValue, 2000)
        XCTAssertEqual(payload["dataValue"] as? String, "AQID")
        XCTAssertEqual(payload["urlValue"] as? String, "https://example.com/a")
        XCTAssertEqual((payload["intValue"] as? NSNumber)?.intValue, 7)
        XCTAssertEqual((payload["doubleValue"] as? NSNumber)?.doubleValue, 1.5)
        XCTAssertEqual((payload["boolValue"] as? NSNumber)?.boolValue, true)
        XCTAssertEqual(payload["stringValue"] as? String, "text")
        XCTAssertTrue(payload["nullValue"] is NSNull)
        XCTAssertEqual(payload["nestedDict"] as? [String: String], ["innerKey": "innerValue"])
        XCTAssertEqual((payload["optionalValue"] as? NSNumber)?.intValue, 3)
        // 显式 nil（Optional.none as Any）无法用「缺失键」表达，只能以 Optional.none 存在，
        // 统一动态桥把它解包为 JSON null（AnyEncodableBox.swift:88-89）。
        XCTAssertTrue(payload["nilOptionalValue"] is NSNull)

        let array = try XCTUnwrap(payload["nestedArray"] as? [Any])
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual((array[0] as? NSNumber)?.intValue, 1)
        XCTAssertEqual(array[1] as? String, "two")
        XCTAssertEqual((array[2] as? NSNumber)?.boolValue, true)

        XCTAssertEqual((payload["nestedModel"] as? [String: String])?["user_name"], "CHILD")

        // 数据键保持原样（策略会改写的键）
        XCTAssertNil(payload["date_value"])
        XCTAssertNil(payload["nested_dict"])
    }

    // MARK: - (e) 嵌套的不支持叶子抛出 invalidValue，codingPath 为嵌套路径

    func testUnsupportedNestedLeafThrowsInvalidValueWithNestedCodingPath() throws {
        struct Model: SmartCodableX {
            @SmartCompact.Dictionary var payload: [String: Any] = [
                "nestedPayload": ["opaqueValue": F03Opaque()]
            ]
        }

        let encoder = SmartJSONEncoder()
        encoder.smartDynamicValueEncodingStrategy = .recursive
        encoder.smartKeyEncodingStrategy = .toSnakeCase

        XCTAssertThrowsError(try encoder.encode(Model())) { error in
            guard case EncodingError.invalidValue(_, let context) = error else {
                return XCTFail("unexpected error: \(error)")
            }
            XCTAssertEqual(context.codingPath.map(\.stringValue),
                           ["payload", "nestedPayload", "opaqueValue"])
        }
    }

    // MARK: - (f) legacy 行为保持不变

    /// 便于报告引用：把解析后的字典按 key 排序输出（不依赖 JSON 字符串顺序）。
    private static func describe(_ payload: [String: Any]) -> String {
        "[" + payload.keys.sorted().map { "\($0): \(describeValue(payload[$0]))" }.joined(separator: ", ") + "]"
    }

    private static func describeValue(_ value: Any?) -> String {
        guard let value = value else { return "nil" }
        if let dictionary = value as? [String: Any] { return describe(dictionary) }
        if let array = value as? [Any] {
            return "[" + array.map { describeValue($0) }.joined(separator: ", ") + "]"
        }
        return "\(value)"
    }

    func testLegacyModeKeepsConvertedDataKeysAndDropsUnsupportedItems() throws {
        struct Model: SmartCodableX {
            @SmartCompact.Dictionary var payload: [String: Any] = [
                "firstName": 1,
                "otherName": 2,
                "badValue": F03Opaque(),
                "goodValue": 3
            ]
        }

        let json = try encodedJSON(Model(), recursive: false)
        let payload = try XCTUnwrap(json["payload"] as? [String: Any])
        print("F03-LEGACY-FULL: " + Self.describe(json))
        print("F03-LEGACY-PAYLOAD: " + Self.describe(payload))

        XCTAssertEqual(Set(payload.keys), ["first_name", "other_name", "good_value"])
        XCTAssertEqual((payload["first_name"] as? NSNumber)?.intValue, 1)
        XCTAssertEqual((payload["other_name"] as? NSNumber)?.intValue, 2)
        XCTAssertEqual((payload["good_value"] as? NSNumber)?.intValue, 3)
        XCTAssertNil(payload["badValue"])
        XCTAssertNil(payload["firstName"])
    }

    func testLegacyModeStillCollapsesCollidingDataKeys() throws {
        struct Model: SmartCodableX {
            @SmartCompact.Dictionary var payload: [String: Any] = ["firstName": 1, "first_name": 2]
        }

        let json = try encodedJSON(Model(), recursive: false)
        let payload = try XCTUnwrap(json["payload"] as? [String: Any])
        print("F03-COUNTEREXAMPLE-LEGACY: " + Self.describe(payload))

        XCTAssertEqual(payload.keys.sorted(), ["first_name"],
                       "observed payload: \(payload)")
        let survivor = (payload["first_name"] as? NSNumber)?.intValue
        XCTAssertTrue(survivor == 1 || survivor == 2, "observed payload: \(payload)")
    }

    // MARK: - 转换后可能碰撞的重复键不得触发崩溃

    func testRecursiveModeSurvivesKeysThatCollideAfterConversion() throws {
        struct Model: SmartCodableX {
            @SmartCompact.Dictionary var payload: [String: Any] = [
                "firstName": 1,
                "first_name": 2,
                "FIRSTNAME": 3,
                "first name": 4
            ]
        }

        let json = try encodedJSON(Model(), recursive: true)
        let payload = try XCTUnwrap(json["payload"] as? [String: Any])

        XCTAssertEqual(payload.count, 4, "observed payload: \(payload)")
        XCTAssertEqual((payload["firstName"] as? NSNumber)?.intValue, 1)
        XCTAssertEqual((payload["first_name"] as? NSNumber)?.intValue, 2)
        XCTAssertEqual((payload["FIRSTNAME"] as? NSNumber)?.intValue, 3)
        XCTAssertEqual((payload["first name"] as? NSNumber)?.intValue, 4)
    }
}
