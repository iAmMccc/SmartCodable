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
        var dictionary = Model(), string = Model(), data = Model()
        SmartUpdater.update(&dictionary, from: ["value": NSNull()])
        SmartUpdater.update(&string, from: payload)
        SmartUpdater.update(&data, from: Data(payload.utf8))
        for model in [dictionary, string, data] {
            // Both fixed snapshots restore the declared Optional default on null.
            XCTAssertEqual(model.value, 7)
            XCTAssertEqual(model.name, "old")
        }
        var missing = Model()
        SmartUpdater.update(&missing, from: ["name": "new"])
        XCTAssertEqual(missing.value, 7)
        XCTAssertEqual(missing.name, "new")
    }
}
