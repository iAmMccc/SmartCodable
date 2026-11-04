import Foundation
import XCTest
@testable import SmartCodable

final class RootCauseFixTests: XCTestCase {
    func testOriginalIntegerRangeIsCheckedBeforeRounding() throws {
        struct Model: SmartCodableX { var value: UInt8 = 191 }
        let previous = SmartCodableOptions.numberStrategy
        defer { SmartCodableOptions.numberStrategy = previous }
        for strategy: SmartCodableOptions.NumberConversionStrategy in [.strict, .truncate, .rounded] {
            SmartCodableOptions.numberStrategy = strategy
            for token in ["255.4", "-0.4", "2.554e2", "-4e-1"] {
                XCTAssertEqual(try XCTUnwrap(Model.deserialize(from: ["value": token])).value, 191,
                               "\(strategy)/\(token)")
            }
        }
    }

    private struct Upper: ValueTransformable {
        typealias Object = String
        typealias JSON = String
        func transformFromJSON(_ value: Any) -> String? { value as? String }
        func transformToJSON(_ value: String) -> String? { value.uppercased() }
    }

    private enum Expected: Error { case failure }

    private struct Throwing: SmartCodableX {
        var value = "bad"
        static func mappingForValue() -> [SmartValueTransformer]? {
            [CodingKeys.value <--- Upper()]
        }
        func encode(to encoder: Encoder) throws { throw Expected.failure }
    }

    private struct Plain: Encodable { var value = "fallback" }

    private struct Recover: Encodable {
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            do { try container.encode(Optional(Throwing())) } catch Expected.failure { }
            try container.encode(Plain())
        }
    }

    func testCaughtEncodingFailureCannotLeakTransformerIntoFallback() throws {
        let object = try JSONSerialization.jsonObject(with: SmartJSONEncoder().encode(Recover()))
        XCTAssertEqual(object as? [String: String], ["value": "fallback"])
    }

    func testCanonicalEncodingKeyCannotBorrowAnotherFieldsAliasTransformer() throws {
        struct Model: SmartCodableX {
            var firstName = "first"
            var name = "independent"
            static func mappingForKey() -> [SmartKeyTransformer]? { [CodingKeys.firstName <--- ["name", "first_name"]] }
            static func mappingForValue() -> [SmartValueTransformer]? { [CodingKeys.firstName <--- Upper()] }
        }
        let encoded = try XCTUnwrap(Model().toDictionary())
        XCTAssertEqual(encoded["firstName"] as? String, "FIRST")
        XCTAssertEqual(encoded["name"] as? String, "independent")
    }
}
