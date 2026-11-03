import CoreFoundation
import Foundation
import XCTest

/// Test-only JSON oracle. Foundation parses input; SmartCodable's JSONValue
/// and Patcher never participate in expected-result construction.
enum ReferenceJSON: Equatable {
    case null
    case bool(Bool)
    case number(String)
    case string(String)
    case array([ReferenceJSON])
    case object([String: ReferenceJSON])

    static func parse(_ text: String) throws -> Self {
        let raw = try JSONSerialization.jsonObject(with: Data(text.utf8), options: .fragmentsAllowed)
        return try convert(raw)
    }

    private static func convert(_ value: Any) throws -> Self {
        switch value {
        case is NSNull:
            return .null
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return .bool(number.boolValue)
            }
            guard number.doubleValue.isFinite else {
                throw OracleError.nonFiniteNumber
            }
            // This oracle is used on integer inputs representable by Int64/UInt64.
            // Keep their exact decimal representation; never use Double to compare.
            let text = number.stringValue
            return .number(text == "-0" ? "0" : text)
        case let text as String:
            return .string(text)
        case let values as [Any]:
            return .array(try values.map(convert))
        case let values as [String: Any]:
            return .object(try values.mapValues(convert))
        default:
            throw OracleError.unsupportedType
        }
    }

    enum OracleError: Error {
        case nonFiniteNumber, unsupportedType
    }
}

final class JSONOracleTests: XCTestCase {
    func testBooleanAndNumericTypesNeverCompareEqual() throws {
        XCTAssertNotEqual(try ReferenceJSON.parse("true"), try ReferenceJSON.parse("1"))
        XCTAssertNotEqual(try ReferenceJSON.parse("false"), try ReferenceJSON.parse("0"))
        XCTAssertFalse(TestSupport.deepEqual(NSNumber(value: true), NSNumber(value: 1)))
        XCTAssertFalse(TestSupport.deepEqual(NSNumber(value: false), NSNumber(value: 0)))
    }

    func testAdjacentIntegersBeyondDoublePrecisionNeverCompareEqual() throws {
        let first = "9007199254740992"
        let second = "9007199254740993"
        XCTAssertNotEqual(try ReferenceJSON.parse(first), try ReferenceJSON.parse(second))
        XCTAssertFalse(TestSupport.deepEqual(NSNumber(value: Int64(first)!), NSNumber(value: Int64(second)!)))
    }

    func testAdjacentUnsignedValuesNearUInt64MaxDoNotUseDouble() {
        XCTAssertFalse(TestSupport.deepEqual(NSNumber(value: UInt64.max),
                                             NSNumber(value: UInt64.max - 1)))
    }

    func testObjectOrderIsIgnoredAndArrayOrderIsPreserved() throws {
        XCTAssertEqual(try ReferenceJSON.parse(#"{"a":1,"b":true}"#),
                       try ReferenceJSON.parse(#"{"b":true,"a":1}"#))
        XCTAssertNotEqual(try ReferenceJSON.parse("[1,2]"), try ReferenceJSON.parse("[2,1]"))
    }

    func testMissingKeyDiffersFromExplicitNull() throws {
        XCTAssertNotEqual(try ReferenceJSON.parse("{}"), try ReferenceJSON.parse(#"{"a":null}"#))
    }

    func testNegativeZeroIsEqualWithinIntegerDomain() throws {
        XCTAssertEqual(try ReferenceJSON.parse("-0"), try ReferenceJSON.parse("0"))
    }

    func testNaNIsOutsideJSONDomain() throws {
        XCTAssertThrowsError(try ReferenceJSON.parse("NaN"))
    }
}
