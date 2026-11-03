import XCTest
import Foundation
@testable import SmartCodable

final class Branch702ReviewRegressionTests: XCTestCase {
    func testR1FloatStringTransformerTakesPriority() throws {
        struct Model: SmartCodableX {
            var value: Double = -1
            static func mappingForValue() -> [SmartValueTransformer]? {
                [CodingKeys.value <--- FastTransformer<Double, String>(fromJSON: { $0 == "3.5" ? 42 : nil })]
            }
        }
        XCTAssertEqual(Model.deserialize(from: ["value": "3.5"])?.value, 42)
        XCTAssertEqual(Model.deserialize(from: ["value": "4.5"])?.value, 4.5)
    }

    func testR1FloatString() throws {
        struct Model: SmartCodableX { var value: Double = -1 }
        let model = try XCTUnwrap(Model.deserialize(from: ["value": "3.5"]))
        XCTAssertEqual(model.value, 3.5)
    }

    func testR1FloatingContainers() throws {
        struct Model: SmartCodableX {
            var float: Float = -1
            var double: Double = -1
            var cg: CGFloat = -1
            var optional: Double? = -1
            var values: [Double] = []
            @SmartCompact.Array var compact: [Double] = []
        }
        for value: Any in ["3.5", 3.5] {
            let model = try XCTUnwrap(Model.deserialize(from: ["float": value, "double": value, "cg": value, "optional": value, "values": [value, "-2.5", "1e-5"], "compact": [value, "-2.5", "1e-5"]]))
            XCTAssertEqual(model.float, 3.5)
            XCTAssertEqual(model.double, 3.5)
            XCTAssertEqual(model.cg, 3.5)
            XCTAssertEqual(model.optional, 3.5)
            XCTAssertEqual(model.values.count, 3)
            XCTAssertEqual(model.compact.count, 3)
            guard model.values.count == 3, model.compact.count == 3 else { continue }
            XCTAssertEqual(model.values[0], 3.5)
            XCTAssertEqual(model.values[1], -2.5)
            XCTAssertEqual(model.values[2], 0.00001, accuracy: 1e-12)
            XCTAssertEqual(model.compact[0], 3.5)
            XCTAssertEqual(model.compact[1], -2.5)
            XCTAssertEqual(model.compact[2], 0.00001, accuracy: 1e-12)
        }
    }

    func testR1ConfiguredNonFiniteTokens() throws {
        struct Model: SmartCodableX { var value: Double = -1 }
        let options: Set<SmartDecodingOption> = [.float(.convertFromString(positiveInfinity: "positive", negativeInfinity: "negative", nan: "not-a-number"))]
        let positive = try XCTUnwrap(Model.deserialize(from: ["value": "positive"], options: options))
        let negative = try XCTUnwrap(Model.deserialize(from: ["value": "negative"], options: options))
        let nan = try XCTUnwrap(Model.deserialize(from: ["value": "not-a-number"], options: options))
        XCTAssertEqual(positive.value, .infinity)
        XCTAssertEqual(negative.value, -.infinity)
        XCTAssertTrue(nan.value.isNaN)
    }

}
