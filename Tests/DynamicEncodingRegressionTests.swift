import Foundation
import XCTest
@testable import SmartCodable

private struct DynamicUpperTransformer: ValueTransformable {
    typealias Object = String
    typealias JSON = String

    func transformFromJSON(_ value: Any) -> String? { (value as? String)?.uppercased() }
    func transformToJSON(_ value: String) -> String? { value.uppercased() }
}

private struct DynamicChild: SmartCodableX {
    var name = "child"

    static func mappingForValue() -> [SmartValueTransformer]? {
        [CodingKeys.name <--- DynamicUpperTransformer()]
    }
}

private struct DynamicPlain: Codable {
    var label = "plain"
}

final class DynamicEncodingRegressionTests: XCTestCase {
    func testSmartAnyUsesDateStrategyAndKeepsOtherCodableValues() throws {
        struct Model: SmartCodableX {
            @SmartAny var date: Any? = Date(timeIntervalSince1970: 2)
            @SmartAny var data: Any? = Data([1, 2, 3])
            @SmartAny var url: Any? = URL(string: "https://example.com/a")!
            @SmartAny var plain: Any? = DynamicPlain()
            @SmartAny var child: Any? = DynamicChild()
        }

        // Default strategy: only `SmartCodableX` runtime values encode; Date/Data/URL
        // and plain Encodable values keep the historical null fallback.
        let legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: SmartJSONEncoder().encode(Model())) as? [String: Any])
        XCTAssertTrue(legacy["date"] is NSNull)
        XCTAssertTrue(legacy["data"] is NSNull)
        XCTAssertTrue(legacy["url"] is NSNull)
        XCTAssertTrue(legacy["plain"] is NSNull)
        XCTAssertEqual((legacy["child"] as? [String: String])?["name"], "CHILD")

        let encoder = SmartJSONEncoder()
        encoder.smartDynamicValueEncodingStrategy = .recursive
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(Model())) as? [String: Any])
        XCTAssertEqual((json["date"] as? NSNumber)?.doubleValue, 2000)
        XCTAssertEqual(json["data"] as? String, "AQID")
        XCTAssertEqual(json["url"] as? String, "https://example.com/a")
        XCTAssertEqual((json["plain"] as? [String: String])?["label"], "plain")
        XCTAssertEqual((json["child"] as? [String: String])?["name"], "CHILD")
    }

    func testCompactDictionaryEncodesRuntimeValuesAndChildSnapshot() throws {
        struct Model: SmartCodableX {
            @SmartCompact.Dictionary var info: [String: Any] = [
                "date": Date(timeIntervalSince1970: 2),
                "data": Data([1, 2, 3]),
                "url": URL(string: "https://example.com/a")!,
                "plain": DynamicPlain(),
                "child": DynamicChild(),
                "number": 7,
                "nested": ["name": "value"]
            ]
        }

        let encoder = SmartJSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(Model())) as? [String: Any])
        let info = try XCTUnwrap(json["info"] as? [String: Any])
        XCTAssertEqual((info["date"] as? NSNumber)?.doubleValue, 2000)
        XCTAssertEqual(info["data"] as? String, "AQID")
        XCTAssertEqual(info["url"] as? String, "https://example.com/a")
        XCTAssertEqual((info["plain"] as? [String: String])?["label"], "plain")
        XCTAssertEqual((info["child"] as? [String: String])?["name"], "CHILD")
        XCTAssertEqual((info["number"] as? NSNumber)?.intValue, 7)
        XCTAssertEqual((info["nested"] as? [String: String])?["name"], "value")
    }

    func testCompactDictionaryStillSkipsUnrepresentableValues() throws {
        struct Opaque {}
        struct Model: SmartCodableX {
            @SmartCompact.Dictionary var info: [String: Any] = ["bad": Opaque(), "good": 7]
        }

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: SmartJSONEncoder().encode(Model())) as? [String: Any])
        let info = try XCTUnwrap(json["info"] as? [String: Any])
        XCTAssertNil(info["bad"])
        XCTAssertEqual((info["good"] as? NSNumber)?.intValue, 7)
    }

    func testHeterogeneousDictionaryDateKeepsExistingFallback() throws {
        struct Model: SmartCodableX {
            @SmartAny var info: [String: Any] = ["date": Date(timeIntervalSince1970: 0)]
            @SmartCompact.Dictionary var compact: [String: Any] = [
                "nested": ["date": Date(timeIntervalSince1970: 0)] as [String: Any]
            ]
        }

        let encoder = SmartJSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let actual = try XCTUnwrap(String(data: encoder.encode(Model()), encoding: .utf8))
        let historicalShape = #"{"info":{"date":null},"compact":{}}"#
        XCTAssertEqual(try ReferenceJSON.parse(actual), try ReferenceJSON.parse(historicalShape), actual)
    }

    func testRecursiveCompactDictionaryRetainsHeterogeneousDateParent() throws {
        struct Model: SmartCodableX {
            @SmartAny var info: [String: Any] = ["date": Date(timeIntervalSince1970: 0)]
            @SmartCompact.Dictionary var compact: [String: Any] = [
                "nested": ["date": Date(timeIntervalSince1970: 0)] as [String: Any]
            ]
        }

        let encoder = SmartJSONEncoder()
        encoder.smartDynamicValueEncodingStrategy = .recursive
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let actual = try XCTUnwrap(String(data: encoder.encode(Model()), encoding: .utf8))
        let expected = #"{"info":{"date":0},"compact":{"nested":{"date":0}}}"#
        XCTAssertEqual(try ReferenceJSON.parse(actual), try ReferenceJSON.parse(expected), actual)
    }
}
