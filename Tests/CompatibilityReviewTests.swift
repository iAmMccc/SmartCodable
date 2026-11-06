import Foundation
import XCTest
@testable import SmartCodable

/// Historical contracts: failures must be distinguished from an empty object
/// that successfully decodes using declared defaults.
final class CompatibilityReviewTests: XCTestCase {
    private struct Positive: Decodable {
        let value: Int
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            value = try container.decode(Int.self)
            guard value > 0 else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "positive required")
            }
        }
    }

    private struct Cursor: SmartCodableX {
        var values: [Int?] = []
        var indices: [Int] = []
        init() {}
        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            while !container.isAtEnd {
                values.append(try container.decodeIfPresent(Positive.self)?.value)
                indices.append(container.currentIndex)
            }
        }
    }

    func testHistoricalGenericOptionalCursorThroughPublicEntrypoints() throws {
        // Compatibility observation, not a recommendation for a new contract.
        let deserialize = try XCTUnwrap(Cursor.deserialize(from: "[0,2,3]"))
        let decoder = try SmartJSONDecoder().smartDecode(Cursor.self, from: "[0,2,3]")
        for result in [deserialize, decoder] {
            XCTAssertEqual(result.values, [nil, 3])
            XCTAssertEqual(result.indices, [2, 3])
        }
    }

    private struct Child: SmartCodableX {
        var id = -1
        var calls = 0
        mutating func didFinishMapping() { calls += 1; id += 10 }
    }
    private struct Host: SmartCodableX {
        var ordinary: [Child] = [Child(id: 90)]
        var nested: [[Child]] = [[Child(id: 91)]]
        @SmartCompact.Array var compact: [Child] = []
    }

    func testOrdinaryAndNestedModelArraysKeepDeclaredFallbackOnActualFailure() throws {
        for bad: Any in [NSNull(), "bad", [] as [Int]] {
            let elements: [Any] = [["id": 1], bad, ["id": 2]]
            let host = try XCTUnwrap(Host.deserialize(from: [
                "ordinary": elements, "nested": [elements], "compact": elements
            ]))
            XCTAssertEqual(host.ordinary.map(\.id), [90])
            XCTAssertEqual(host.nested.map { $0.map(\.id) }, [[91]])
            XCTAssertEqual(host.compact.map(\.id), [11, 12])
            XCTAssertEqual(host.compact.map(\.calls), [1, 1])
        }
    }

    func testDefaultedObjectsRemainElementsAndCompleteExactlyOnce() throws {
        for object: [String: Any] in [[:], ["other": 1], ["id": "bad"]] {
            let elements: [Any] = [["id": 1], object, ["id": 2]]
            let host = try XCTUnwrap(Host.deserialize(from: [
                "ordinary": elements, "nested": [elements], "compact": elements
            ]))
            XCTAssertEqual(host.ordinary.map(\.id), [11, 9, 12])
            XCTAssertEqual(host.ordinary.map(\.calls), [1, 1, 1])
            XCTAssertEqual(host.nested.map { $0.map(\.id) }, [[11, 9, 12]])
            XCTAssertEqual(host.compact.map(\.id), [11, 9, 12])
            XCTAssertEqual(host.compact.map(\.calls), [1, 1, 1])
        }
    }

    private struct Upper: ValueTransformable {
        typealias Object = String
        typealias JSON = String
        func transformFromJSON(_ value: Any) -> String? { value as? String }
        func transformToJSON(_ value: String) -> String? { value.uppercased() }
    }
    private struct Dynamic: SmartCodableX {
        var value = "child"
        static func mappingForValue() -> [SmartValueTransformer]? {
            [CodingKeys.value <--- Upper()]
        }
        static func mappingForKey() -> [SmartKeyTransformer]? {
            [CodingKeys.value <--- "output"]
        }
    }

    func testDynamicModelSnapshotsAndMappedKeysHaveCorrectSemanticOutput() throws {
        struct Box: Encodable {
            let value: any Encodable
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(value)
            }
        }
        let encoder = SmartJSONEncoder()
        // Mapping and transformer ownership must survive existential and Optional boundaries.
        encoder.userInfo[CodingUserInfoKey(rawValue: "Smart.useMappedKeys")!] = true
        let dynamic: any Encodable = Dynamic()
        for box in [Box(value: dynamic), Box(value: Optional(Dynamic())), Box(value: [Dynamic()])] {
            let object = try JSONSerialization.jsonObject(with: encoder.encode(box))
            if let array = object as? [[String: String]] {
                XCTAssertEqual(array, [["output": "CHILD"]])
            } else {
                XCTAssertEqual(object as? [String: String], ["output": "CHILD"])
            }
        }
    }

    func testHistoricalUpdaterOptionalDefaultForNullAndMissingAcrossEntrypoints() throws {
        struct Model: SmartCodableX { var value: Int? = 7; var name = "old" }
        let payload = "{\"value\":null}"
        var dictionary = Model(value: 73, name: "old")
        var string = Model(value: 73, name: "old")
        var data = Model(value: 73, name: "old")
        SmartUpdater.update(&dictionary, from: ["value": NSNull()])
        SmartUpdater.update(&string, from: payload)
        SmartUpdater.update(&data, from: Data(payload.utf8))
        for model in [dictionary, string, data] {
            // A present null restores the declared default, even when the target was changed.
            XCTAssertEqual(model.value, 7)
            XCTAssertEqual(model.name, "old")
        }

        var missingDictionary = Model(value: 73, name: "old")
        var missingString = Model(value: 73, name: "old")
        var missingData = Model(value: 73, name: "old")
        SmartUpdater.update(&missingDictionary, from: ["name": "new"])
        SmartUpdater.update(&missingString, from: "{\"name\":\"new\"}")
        SmartUpdater.update(&missingData, from: Data("{\"name\":\"new\"}".utf8))
        for model in [missingDictionary, missingString, missingData] {
            // A missing key leaves the existing target value intact.
            XCTAssertEqual(model.value, 73)
            XCTAssertEqual(model.name, "new")
        }
    }

    // MARK: - Compact arrays with Optional elements

    private struct CompactOptionalHost: SmartCodableX {
        @SmartCompact.Array var ints: [Int?] = []
        @SmartCompact.Array var strings: [String?] = []
        @SmartCompact.Array var bools: [Bool?] = []
        @SmartCompact.Array var doubles: [Double?] = []
    }

    func testCompactOptionalElementsDropNullsInsteadOfRetainingPlaceholders() throws {
        let host = try XCTUnwrap(CompactOptionalHost.deserialize(from: [
            "ints": [1, NSNull(), 2] as [Any],
            "strings": ["a", NSNull(), "c"] as [Any],
            "bools": [true, NSNull(), false] as [Any],
        ]))
        // 7.0.1 bridges the raw JSON value and casts it to `T`, so null elements are
        // dropped. Retaining `Optional.none` would change the array length and the
        // positions of every element after the first null.
        XCTAssertEqual(host.ints.count, 2)
        XCTAssertEqual(host.ints, [1, 2])
        XCTAssertEqual(host.strings.count, 2)
        XCTAssertEqual(host.strings, ["a", "c"])
        XCTAssertEqual(host.bools.count, 2)
        XCTAssertEqual(host.bools, [true, false])
    }

    func testCompactOptionalElementsKeepLegacyAcceptanceDomain() throws {
        // Elements that never bridged to `T` under the JSON-value cast stay dropped,
        // even when the current scalar decoders could convert them.
        let cases: [(input: [Any], expected: [Int?])] = [
            ([1, "bad", 2], [1, 2]),
            ([1, [7] as [Any], 2], [1, 2]),
            ([1, ["k": 1] as [String: Any], 2], [1, 2]),
            ([NSNull(), NSNull()], []),
            ([1.5, NSNull(), 2.5], []),
            (["1", NSNull(), "2"], []),
        ]
        for (input, expected) in cases {
            let host = try XCTUnwrap(CompactOptionalHost.deserialize(from: ["ints": input]))
            XCTAssertEqual(host.ints, expected, "unexpected acceptance for \(input)")
        }

        let valid = try XCTUnwrap(CompactOptionalHost.deserialize(from: [
            "ints": [1, 2, 3] as [Any],
            "doubles": [1.5, NSNull(), 2.5] as [Any],
        ]))
        XCTAssertEqual(valid.ints, [1, 2, 3])
        XCTAssertEqual(valid.doubles, [1.5, 2.5])
    }

    func testCompactOptionalNestedOptionalElementsDropNulls() throws {
        struct Host: SmartCodableX {
            @SmartCompact.Array var values: [Int??] = []
        }
        let host = try XCTUnwrap(Host.deserialize(from: ["values": [1, NSNull(), 2] as [Any]]))
        XCTAssertEqual(host.values.count, 2)
        XCTAssertEqual(host.values.compactMap { $0 ?? nil }, [1, 2])
    }

    func testOrdinaryOptionalArraysKeepNullPlaceholders() throws {
        // The Compact element boundary must not change ordinary Optional arrays.
        struct Host: SmartCodableX {
            var values: [Int?] = []
        }
        let host = try XCTUnwrap(Host.deserialize(from: ["values": [1, NSNull(), 2] as [Any]]))
        XCTAssertEqual(host.values.count, 3)
        XCTAssertEqual(host.values, [1, nil, 2])
    }
    func testCompactScalarElementsDefaultToLegacyAcceptanceDomain() throws {
        // 7.0.1 only appended an element when the bridged JSON value already
        // matched the declared type. The conversion domain stays opt-in.
        struct Host: SmartCodableX {
            @SmartCompact.Array var ints: [Int] = []
            @SmartCompact.Array var bools: [Bool] = []
            @SmartCompact.Array var strings: [String] = []
        }
        let json: [String: Any] = [
            "ints": [1, "2", "bad", NSNull(), 3.5, true] as [Any],
            "bools": ["YES", true, 0] as [Any],
            "strings": [1, "a", true] as [Any],
        ]
        let previous = SmartCodableOptions.compactElementStrategy
        defer { SmartCodableOptions.compactElementStrategy = previous }

        SmartCodableOptions.compactElementStrategy = .legacy
        let legacy = try XCTUnwrap(Host.deserialize(from: json))
        XCTAssertEqual(legacy.ints, [1, 1])
        XCTAssertEqual(legacy.bools, [true, false])
        XCTAssertEqual(legacy.strings, ["a"])

        SmartCodableOptions.compactElementStrategy = .convert
        let converted = try XCTUnwrap(Host.deserialize(from: json))
        XCTAssertEqual(converted.ints, [1, 2])
        XCTAssertEqual(converted.bools, [true, true, false])
        XCTAssertEqual(converted.strings, ["1", "a"])
    }

    func testCompactPlainCodableElementsRequireConversionOptIn() throws {
        struct Plain: Codable, Equatable {
            var a: Int
        }
        struct Host: SmartCodableX {
            @SmartCompact.Array var items: [Plain] = []
        }
        let previous = SmartCodableOptions.compactElementStrategy
        defer { SmartCodableOptions.compactElementStrategy = previous }

        SmartCodableOptions.compactElementStrategy = .legacy
        XCTAssertEqual(Host.deserialize(from: ["items": [["a": 1]]])?.items, [])

        SmartCodableOptions.compactElementStrategy = .convert
        XCTAssertEqual(Host.deserialize(from: ["items": [["a": 1]]])?.items, [Plain(a: 1)])
    }

    func testCompactModelElementsKeepLegacyDecodingAndCallbacks() throws {
        struct Host: SmartCodableX {
            @SmartCompact.Array var values: [CompactCallbackChild] = []
        }
        let previous = SmartCodableOptions.compactElementStrategy
        defer { SmartCodableOptions.compactElementStrategy = previous }

        for strategy in [SmartCodableOptions.CompactElementStrategy.legacy, .convert] {
            SmartCodableOptions.compactElementStrategy = strategy
            let host = try XCTUnwrap(Host.deserialize(from: [
                "values": [["id": 1], NSNull(), "bad", ["id": 2]] as [Any],
            ]))
            XCTAssertEqual(host.values.map(\.id), [11, 12], "\(strategy)")
            XCTAssertEqual(host.values.map(\.calls), [1, 1], "\(strategy)")
        }
    }
    func testCompactElementEncodingFollowsTheSameStrategy() throws {
        // The encode side mirrors the decode side: `.legacy` bridges the element and
        // does not invoke a plain Encodable; `.convert` uses its conformance.
        let counter = EncodeCounter()
        struct Host: SmartCodableX {
            @SmartCompact.Array var values: [CountingElement] = []
        }
        var host = Host()
        host.values = [CountingElement(counter: counter)]

        let previous = SmartCodableOptions.compactElementStrategy
        defer { SmartCodableOptions.compactElementStrategy = previous }

        SmartCodableOptions.compactElementStrategy = .legacy
        let legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: SmartJSONEncoder().encode(host)) as? [String: Any])
        XCTAssertEqual((legacy["values"] as? [Any])?.count, 1)
        XCTAssertTrue((legacy["values"] as? [Any])?.first is NSNull)
        XCTAssertEqual(counter.calls, 0)

        SmartCodableOptions.compactElementStrategy = .convert
        let converted = try XCTUnwrap(JSONSerialization.jsonObject(with: SmartJSONEncoder().encode(host)) as? [String: Any])
        XCTAssertEqual(converted["values"] as? [Int], [7])
        XCTAssertEqual(counter.calls, 1)

        // Foundation values follow the same mode: the legacy bridge emits null, while
        // `.convert` keeps the element's own encoding.
        struct FoundationHost: SmartCodableX {
            @SmartCompact.Array var dates: [Date] = []
            @SmartCompact.Array var data: [Data] = []
        }
        var foundation = FoundationHost()
        foundation.dates = [Date(timeIntervalSinceReferenceDate: 0)]
        foundation.data = [Data([1, 2, 3])]

        SmartCodableOptions.compactElementStrategy = .legacy
        let legacyFoundation = try XCTUnwrap(JSONSerialization.jsonObject(with: SmartJSONEncoder().encode(foundation)) as? [String: Any])
        XCTAssertTrue((legacyFoundation["dates"] as? [Any])?.first is NSNull)
        XCTAssertTrue((legacyFoundation["data"] as? [Any])?.first is NSNull)

        SmartCodableOptions.compactElementStrategy = .convert
        let convertedFoundation = try XCTUnwrap(JSONSerialization.jsonObject(with: SmartJSONEncoder().encode(foundation)) as? [String: Any])
        XCTAssertEqual(convertedFoundation["data"] as? [String], ["AQID"])
        XCTAssertNotNil((convertedFoundation["dates"] as? [Any])?.first as? Double)
    }
}

private final class EncodeCounter {
    var calls = 0
}

private struct CountingElement: Encodable {
    let counter: EncodeCounter

    func encode(to encoder: Encoder) throws {
        counter.calls += 1
        var container = encoder.singleValueContainer()
        try container.encode(7)
    }
}

private struct CompactCallbackChild: SmartCodableX {
    var id = -1
    var calls = 0
    mutating func didFinishMapping() {
        calls += 1
        id += 10
    }
}
