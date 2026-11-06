import Foundation
import XCTest
import SmartCodable

final class LegacyInputBoundaryTests: XCTestCase {

    func testDictionaryJSONStringRequiresCallerPreprocessing() throws {
        struct Model: SmartCodableX {
            var d: [String: Int] = ["z": 0]
        }

        let encodedObject = #"{"x":1}"#
        let rawInput: [String: Any] = ["d": encodedObject]
        XCTAssertEqual(Model.deserialize(from: rawInput)?.d, ["z": 0])

        let preparedObject = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(encodedObject.utf8)) as? [String: Any]
        )
        XCTAssertEqual(Model.deserialize(from: ["d": preparedObject])?.d, ["x": 1])
    }

    func testDesignatedPathSkipsEmptySegmentsButMissingComponentsAbort() throws {
        struct Model: SmartCodableX {
            var name: String = "default"
        }

        let input: [String: Any] = [
            "name": "root",
            "a": ["b": ["name": "inner"]],
        ]

        XCTAssertEqual(Model.deserialize(from: input, designatedPath: ".")?.name, "root")
        XCTAssertEqual(Model.deserialize(from: input, designatedPath: " ")?.name, "root")
        XCTAssertEqual(Model.deserialize(from: input, designatedPath: "a..b")?.name, "inner")
        XCTAssertNil(Model.deserialize(from: input, designatedPath: "a.missing"))
    }

    func testStringFragmentsRemainRejectedWhileDataFragmentsDecode() throws {
        let decoder = SmartJSONDecoder()

        XCTAssertThrowsError(try decoder.smartDecode(Int.self, from: "42"))
        XCTAssertEqual(try decoder.smartDecode(Int.self, from: Data("42".utf8)), 42)
    }
}
