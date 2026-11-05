import Foundation
import SmartCodable
import XCTest

final class LegacyHexIntegerTests: XCTestCase {
    private struct Signed: SmartCodableX { var value: Int64 = 91 }
    private struct Unsigned: SmartCodableX { var value: UInt64 = 91 }
    private struct Small: SmartCodableX { var value: UInt8 = 191 }

    private func signed(_ text: String) throws -> Int64 {
        // Exercise a quoted JSON string, not a non-JSON numeric literal.
        let data = try JSONSerialization.data(withJSONObject: ["value": text])
        return try XCTUnwrap(Signed.deserialize(from: data)).value
    }
    private func unsigned(_ text: String) throws -> UInt64 {
        try XCTUnwrap(Unsigned.deserialize(from: ["value": text])).value
    }

    func testHistoricalHexStringsAndDecimalControls() throws {
        let previous = SmartCodableOptions.numberStrategy
        defer { SmartCodableOptions.numberStrategy = previous }
        SmartCodableOptions.numberStrategy = .strict
        for (input, expected): (String, Int64) in [
            ("0x10", 16), ("0x1p4", 16), ("0X1.Ap+4", 26),
            ("+0x10", 16), ("-0x10", -16), ("0x1.", 1),
            ("0x.8p1", 1), ("16", 16), ("1.6e1", 16), ("invalid", 91)
        ] { XCTAssertEqual(try signed(input), expected, input) }
    }

    func testWideHexValuesRemainExactAndCheckOriginalRange() throws {
        let previous = SmartCodableOptions.numberStrategy
        defer { SmartCodableOptions.numberStrategy = previous }
        for policy: SmartCodableOptions.NumberConversionStrategy in [.strict, .truncate, .rounded] {
            SmartCodableOptions.numberStrategy = policy
            XCTAssertEqual(try signed("0x7fffffffffffffff"), Int64.max)
            XCTAssertEqual(try signed("-0x8000000000000000"), Int64.min)
            XCTAssertEqual(try signed("0x20000000000001"), 9_007_199_254_740_993)
            XCTAssertEqual(try unsigned("0xffffffffffffffff"), UInt64.max)
            XCTAssertEqual(try unsigned("0x1fffffffffffffffep-1"), UInt64.max)
            for text in ["0x8000000000000000", "-0x8000000000000000.0001", "0x7fffffffffffffff.0001"] {
                XCTAssertEqual(try signed(text), 91, "\(policy)/\(text)")
            }
            for text in ["0x10000000000000000", "0xffffffffffffffff.0001", "-0x.0001"] {
                XCTAssertEqual(try unsigned(text), 91, "\(policy)/\(text)")
            }
        }
    }

    func testFractionPoliciesAndPreRoundingBounds() throws {
        let previous = SmartCodableOptions.numberStrategy
        defer { SmartCodableOptions.numberStrategy = previous }
        for (policy, positive, negative): (SmartCodableOptions.NumberConversionStrategy, Int64, Int64) in [
            (.strict, 91, 91), (.truncate, 1, -1), (.rounded, 2, -2)
        ] {
            SmartCodableOptions.numberStrategy = policy
            XCTAssertEqual(try signed("0x1.8"), positive)
            XCTAssertEqual(try signed("-0x1.8"), negative)
            for text in ["0xff.01", "-0x.01", "0x100"] {
                XCTAssertEqual(try XCTUnwrap(Small.deserialize(from: ["value": text])).value, 191)
            }
            XCTAssertEqual(try XCTUnwrap(Small.deserialize(from: ["value": "0xfe.8"])).value,
                           policy == .strict ? 191 : (policy == .truncate ? 254 : 255))
            XCTAssertEqual(try signed("0x1p-999999999999999999999"), policy == .strict ? 91 : 0)
            XCTAssertEqual(try signed("0x0p999999999999999999999"), 0)
            XCTAssertEqual(try signed("0x1p999999999999999999999"), 91)
            XCTAssertEqual(try unsigned("-0x0"), 0)
        }
    }

    func testMalformedAndOtherRadixStringsStillFallBack() throws {
        for text in ["0x", "0x.", "0x1p", "0x1p+", "0x1p1.5", "0x1g", "0x1.2.3", " 0x10", "0x10 ", "0b101", "0o17"] {
            XCTAssertEqual(try signed(text), 91, text)
        }
    }
}
