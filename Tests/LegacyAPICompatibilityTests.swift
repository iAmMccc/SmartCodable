import Foundation
import XCTest
import SmartCodable

final class LegacyAPICompatibilityTests: XCTestCase {
    private enum ProbeError: Error, Equatable {
        case expected
    }

    private static var events: [String] = []

    private struct CompactValues: SmartCodableX {
        @SmartCompact.Array var ints: [Int?] = []
        @SmartCompact.Array var strings: [String?] = []
        @SmartCompact.Array var bools: [Bool?] = []
        @SmartCompact.Array var nested: [Int??] = []
        @SmartCompact.Array var compactInts: [Int] = []
        @SmartCompact.Array var shapeInts: [Int?] = []
        @SmartCompact.Array var shapeStrings: [String?] = []
        @SmartCompact.Array var shapeBools: [Bool?] = []
        var ordinary: [Int?] = []
    }

    private struct IntegerDefault: SmartCodableX {
        var value = 91
    }

    private struct Defaults: SmartCodableX {
        var number = 91
        var text = "fallback"
        var optionalNumber: Int? = 7
    }

    private struct Child: SmartCodableX {
        var id = 0

        mutating func didFinishMapping() {
            LegacyAPICompatibilityTests.events.append("callback")
            id += 10
        }
    }

    private struct CompactChildren: SmartCodableX {
        @SmartCompact.Array var optional: [Child?] = []
        @SmartCompact.Array var regular: [Child] = []
    }

    private struct OrdinaryChildren: SmartCodableX {
        var optional: Child? = nil
        var regular: [Child] = []
        var dictionary: [String: Child] = [:]
    }

    private struct UppercaseTransformer: ValueTransformable {
        typealias Object = String
        typealias JSON = String

        func transformFromJSON(_ value: Any) -> String? {
            LegacyAPICompatibilityTests.events.append("transform")
            return (value as? String)?.uppercased()
        }

        func transformToJSON(_ value: String) -> String? { value.lowercased() }
    }

    private struct MappedValue: SmartCodableX {
        var name = "seed"

        private enum CodingKeys: String, CodingKey {
            case name
        }

        static func mappingForKey() -> [SmartKeyTransformer]? {
            [CodingKeys.name <--- "display_name"]
        }

        static func mappingForValue() -> [SmartValueTransformer]? {
            [CodingKeys.name <--- UppercaseTransformer()]
        }
    }

    private struct AnyBox: SmartCodableX {
        @SmartAny var content: Any = 0
    }

    private struct CompactBox<Element>: SmartCodableX {
        @SmartCompact.Array var content: [Element] = []
    }

    private struct RecordingEncodable: Encodable {
        let shouldThrow: Bool

        func encode(to encoder: Encoder) throws {
            LegacyAPICompatibilityTests.events.append("plain")
            if shouldThrow {
                throw ProbeError.expected
            }
            var container = encoder.singleValueContainer()
            try container.encode("plain")
        }
    }

    private struct ThrowingSmartEncodable: SmartCodableX {
        func encode(to encoder: Encoder) throws {
            LegacyAPICompatibilityTests.events.append("smart")
            throw ProbeError.expected
        }
    }

    func testCompactOptionalScalarsFilterNullsAndKeepOrdinaryOptionalNull() throws {
        let json = #"{"ints":[1,null,2],"strings":["a",null,"b"],"bools":[true,null,false],"nested":[1,null,2],"ordinary":[1,null,2]}"#
        let model = try XCTUnwrap(CompactValues.deserialize(from: json))

        XCTAssertEqual(model.ints, [1, 2])
        XCTAssertEqual(model.strings, ["a", "b"])
        XCTAssertEqual(model.bools, [true, false])
        XCTAssertEqual(model.nested.count, 2)
        XCTAssertEqual(model.nested.compactMap { $0 }, [Optional(1), Optional(2)])

        XCTAssertEqual(model.ordinary.count, 3)
        XCTAssertEqual(model.ordinary[0], 1)
        XCTAssertNil(model.ordinary[1])
        XCTAssertEqual(model.ordinary[2], 2)
    }

    func testCompactOptionalScalarsFilterUnsupportedShapes() throws {
        let raw = #"[1,"2","bad",null,{},[],1.5,4]"#
        let json = #"{"shapeInts":\#(raw),"shapeStrings":\#(raw),"shapeBools":\#(raw)}"#
        let model = try XCTUnwrap(CompactValues.deserialize(from: json))

        XCTAssertEqual(model.shapeInts, [1, 4])
        XCTAssertEqual(model.shapeStrings, ["2", "bad"])
        XCTAssertEqual(model.shapeBools, [true])
    }

    func testCompactIntKeepsLegacyCastAcceptanceDomain() throws {
        let model = try XCTUnwrap(CompactValues.deserialize(from: #"{"compactInts":[1,"2","bad",null,4]}"#))
        XCTAssertEqual(model.compactInts, [1, 4])
    }

    func testCompactOptionalModelsKeepHistoricalEmptyArrayAndCallbackBehavior() throws {
        Self.events = []
        let optional = try XCTUnwrap(CompactChildren.deserialize(from: #"{"optional":[{"id":1},null,{"id":2}]}"#))
        XCTAssertTrue(optional.optional.isEmpty)
        XCTAssertTrue(optional.regular.isEmpty)
        XCTAssertEqual(Self.events, [])

        Self.events = []
        let regular = try XCTUnwrap(CompactChildren.deserialize(from: #"{"regular":[{"id":1},{"id":2}]}"#))
        XCTAssertTrue(regular.optional.isEmpty)
        XCTAssertEqual(regular.regular.map(\.id), [11, 12])
        XCTAssertEqual(Self.events, ["callback", "callback"])
    }

    func testOrdinaryDefaultsHandleMissingNullInvalidAndValidValues() throws {
        let missing = try XCTUnwrap(Defaults.deserialize(from: #"{}"#))
        XCTAssertEqual(missing.number, 91)
        XCTAssertEqual(missing.text, "fallback")
        XCTAssertEqual(missing.optionalNumber, 7)

        let null = try XCTUnwrap(Defaults.deserialize(from: #"{"number":null,"text":null,"optionalNumber":null}"#))
        XCTAssertEqual(null.number, 91)
        XCTAssertEqual(null.text, "fallback")
        XCTAssertEqual(null.optionalNumber, 7)

        let invalid = try XCTUnwrap(Defaults.deserialize(from: #"{"number":"bad","text":{}}"#))
        XCTAssertEqual(invalid.number, 91)
        XCTAssertEqual(invalid.text, "fallback")

        let converted = try XCTUnwrap(Defaults.deserialize(from: #"{"text":9}"#))
        XCTAssertEqual(converted.text, "9")

        let valid = try XCTUnwrap(Defaults.deserialize(from: #"{"number":18,"text":"ready","optionalNumber":5}"#))
        XCTAssertEqual(valid.number, 18)
        XCTAssertEqual(valid.text, "ready")
        XCTAssertEqual(valid.optionalNumber, 5)
    }

    func testOrdinaryOptionalArrayAndDictionaryModelsKeepCallbacks() throws {
        Self.events = []
        let optional = try XCTUnwrap(OrdinaryChildren.deserialize(from: #"{"optional":{"id":1}}"#))
        XCTAssertEqual(optional.optional?.id, 11)
        XCTAssertEqual(Self.events, ["callback"])

        Self.events = []
        let array = try XCTUnwrap(OrdinaryChildren.deserialize(from: #"{"regular":[{"id":2},{"id":3}]}"#))
        XCTAssertEqual(array.regular.map(\.id), [12, 13])
        XCTAssertEqual(Self.events, ["callback", "callback"])

        Self.events = []
        let dictionary = try XCTUnwrap(OrdinaryChildren.deserialize(from: #"{"dictionary":{"a":{"id":4},"b":{"id":5}}}"#))
        XCTAssertEqual(dictionary.dictionary.values.map(\.id).sorted(), [4, 5])
        XCTAssertEqual(Self.events, [])
    }

    func testLegacyKeyAndValueMappingRunsOnlyForPresentValues() throws {
        Self.events = []
        let mapped = try XCTUnwrap(MappedValue.deserialize(from: #"{"display_name":"mccc"}"#))
        XCTAssertEqual(mapped.name, "MCCC")
        XCTAssertEqual(Self.events, ["transform"])

        Self.events = []
        let defaulted = try XCTUnwrap(MappedValue.deserialize(from: #"{}"#))
        XCTAssertEqual(defaulted.name, "seed")
        XCTAssertEqual(Self.events, [])
    }

    func testIntegerStringInputsKeepLegacyDefaultAndHexadecimalBehavior() throws {
        let inputs: [(String, Int)] = [
            ("0x10", 16),
            ("0x1p4", 16),
            ("16", 16),
            ("1.6e1", 16),
            ("invalid", 91)
        ]

        for (value, expected) in inputs {
            let json = #"{"value":"\#(value)"}"#
            let model = try XCTUnwrap(IntegerDefault.deserialize(from: json), value)
            XCTAssertEqual(model.value, expected, value)
        }
    }

    func testSmartAnyUsesLegacyNullFallbackWithoutCallingPlainEncodable() throws {
        let values: [(String, Any)] = [
            ("plain success", RecordingEncodable(shouldThrow: false)),
            ("plain throw", RecordingEncodable(shouldThrow: true)),
            ("date", Date(timeIntervalSince1970: 0)),
            ("data", Data([1, 2])),
            ("url", try XCTUnwrap(URL(string: "https://example.com/a")))
        ]

        for (name, value) in values {
            Self.events = []
            var model = AnyBox()
            model.content = value

            let data = try SmartJSONEncoder().encode(model)
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any], name)
            XCTAssertEqual(Set(object.keys), ["content"], name)
            XCTAssertTrue(object["content"] is NSNull, name)
            XCTAssertEqual(String(data: data, encoding: .utf8), #"{"content":null}"#, name)
            XCTAssertEqual(Self.events, [], name)
        }

        Self.events = []
        var model = AnyBox()
        model.content = ThrowingSmartEncodable()
        XCTAssertThrowsError(try SmartJSONEncoder().encode(model)) { error in
            XCTAssertEqual(error as? ProbeError, .expected)
        }
        XCTAssertEqual(Self.events, ["smart"])
    }

    func testCompactEncodingKeepsLegacyPlainAndSmartModelBoundaries() throws {
        let plainValues: [(String, RecordingEncodable)] = [
            ("plain success", RecordingEncodable(shouldThrow: false)),
            ("plain throw", RecordingEncodable(shouldThrow: true))
        ]

        for (name, value) in plainValues {
            Self.events = []
            var model = CompactBox<Any>()
            model.content = [value]

            let data = try SmartJSONEncoder().encode(model)
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any], name)
            let content = try XCTUnwrap(object["content"] as? [Any], name)
            XCTAssertEqual(Set(object.keys), ["content"], name)
            XCTAssertEqual(content.count, 1, name)
            XCTAssertTrue(content[0] is NSNull, name)
            XCTAssertEqual(String(data: data, encoding: .utf8), #"{"content":[null]}"#, name)
            XCTAssertEqual(Self.events, [], name)
        }

        Self.events = []
        var smartModel = CompactBox<ThrowingSmartEncodable>()
        smartModel.content = [ThrowingSmartEncodable()]
        let data = try SmartJSONEncoder().encode(smartModel)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let content = try XCTUnwrap(object["content"] as? [Any])
        XCTAssertEqual(Set(object.keys), ["content"])
        XCTAssertEqual(content.count, 1)
        XCTAssertTrue(content[0] is NSNull)
        XCTAssertEqual(String(data: data, encoding: .utf8), #"{"content":[null]}"#)
        XCTAssertEqual(Self.events, ["smart"])
    }
}
