import Foundation
import SmartCodable
import XCTest

private struct Int8ContractModel: SmartCodableX {
    var value: Int8 = 73
}

private struct UInt8ContractModel: SmartCodableX {
    var value: UInt8 = 191
}

private struct BoolContractModel: SmartCodableX {
    var value: Bool = false
}

private struct Int64ContractModel: SmartCodableX {
    var value: Int64 = 77
}

private struct UInt64ContractModel: SmartCodableX {
    var value: UInt64 = 99
}

final class NumericContractTests: XCTestCase {
    func testEveryInt8FromNumberAndDecimalString() throws {
        for integer in -128...127 {
            for input: Any in [integer, String(integer)] {
                let model = try XCTUnwrap(
                    Int8ContractModel.deserialize(from: ["value": input]),
                    "Int8 input=\(input)"
                )
                XCTAssertEqual(model.value, Int8(integer), "Int8 input=\(input)")
            }
        }
    }

    func testEveryUInt8FromNumberAndDecimalString() throws {
        for integer in 0...255 {
            for input: Any in [integer, String(integer)] {
                let model = try XCTUnwrap(
                    UInt8ContractModel.deserialize(from: ["value": input]),
                    "UInt8 input=\(input)"
                )
                XCTAssertEqual(model.value, UInt8(integer), "UInt8 input=\(input)")
            }
        }
    }

    func testBoolSupportedFiniteDomainAndInvalidValues() throws {
        for (input, expected): (Any, Bool) in [
            (true, true), (false, false), (1, true), (0, false),
            ("1", true), ("0", false), ("YES", true), ("NO", false),
            ("true", true), ("false", false)
        ] {
            let model = try XCTUnwrap(BoolContractModel.deserialize(from: ["value": input]))
            XCTAssertEqual(model.value, expected, "Bool input=\(input)")
        }
        for input: Any in [2, -1, "maybe"] {
            let model = try XCTUnwrap(BoolContractModel.deserialize(from: ["value": input]))
            XCTAssertFalse(model.value, "Invalid Bool input=\(input)")
        }
    }

    func testExactWideIntegerBoundariesAndAdjacentStrings() throws {
        for value in [Int64.min, Int64.min + 1, -1, 0, 1,
                      9_007_199_254_740_992, 9_007_199_254_740_993,
                      Int64.max - 1, Int64.max] {
            let model = try XCTUnwrap(Int64ContractModel.deserialize(from: ["value": String(value)]))
            XCTAssertEqual(model.value, value, "Int64 value=\(value)")
        }
        for value in [UInt64.min, UInt64.min + 1,
                      9_007_199_254_740_992, 9_007_199_254_740_993,
                      UInt64.max - 1, UInt64.max] {
            let model = try XCTUnwrap(UInt64ContractModel.deserialize(from: ["value": String(value)]))
            XCTAssertEqual(model.value, value, "UInt64 value=\(value)")
        }
    }

    func testInvalidWideIntegerBoundariesFallBackForAllPolicies() throws {
        let previous = SmartCodableOptions.numberStrategy
        defer { SmartCodableOptions.numberStrategy = previous }
        for strategy: SmartCodableOptions.NumberConversionStrategy in [.strict, .truncate, .rounded] {
            SmartCodableOptions.numberStrategy = strategy
            let signed = try XCTUnwrap(Int64ContractModel.deserialize(from: ["value": "9223372036854775808"]))
            let unsigned = try XCTUnwrap(UInt64ContractModel.deserialize(from: ["value": "18446744073709551616"]))
            XCTAssertEqual(signed.value, 77, "Int64 overflow; strategy=\(strategy)")
            XCTAssertEqual(unsigned.value, 99, "UInt64 overflow; strategy=\(strategy)")
        }
    }

    func testSignedUnsignedBoundaryByRepresentationAndPolicy() throws {
        let previous = SmartCodableOptions.numberStrategy
        defer { SmartCodableOptions.numberStrategy = previous }
        let policies: [SmartCodableOptions.NumberConversionStrategy] = [.strict, .truncate, .rounded]
        let signedInputs = [-129, -128, 0, 127, 128]
        let unsignedInputs = [-1, 0, 1, 255, 256]
        var cases = 0
        for policy in policies {
            SmartCodableOptions.numberStrategy = policy
            for asString in [false, true] {
                for integer in signedInputs {
                    let input: Any = asString ? String(integer) : integer
                    let result = try XCTUnwrap(Int8ContractModel.deserialize(from: ["value": input]))
                    XCTAssertEqual(result.value, Int8(exactly: integer) ?? 73,
                                   "Int8 policy=\(policy) string=\(asString) input=\(integer)")
                    cases += 1
                }
                for integer in unsignedInputs {
                    let input: Any = asString ? String(integer) : integer
                    let result = try XCTUnwrap(UInt8ContractModel.deserialize(from: ["value": input]))
                    XCTAssertEqual(result.value, UInt8(exactly: integer) ?? 191,
                                   "UInt8 policy=\(policy) string=\(asString) input=\(integer)")
                    cases += 1
                }
            }
        }
        XCTAssertEqual(cases, 60)
    }

    func testFractionalValuesNearSmallIntegerLimits() throws {
        let previous = SmartCodableOptions.numberStrategy
        defer { SmartCodableOptions.numberStrategy = previous }
        let cases: [(String, Int8, Int8, Int8)] = [
            ("127.4", 73, 127, 127),
            ("127.5", 73, 127, 73),
            ("-128.4", 73, -128, -128),
            ("-128.5", 73, -128, 73)
        ]
        let unsignedCases: [(String, UInt8, UInt8, UInt8)] = [
            ("255.4", 191, 255, 255),
            ("255.5", 191, 255, 191),
            ("-0.4", 191, 0, 0),
            ("-0.5", 191, 0, 191)
        ]
        for (text, strict, truncated, rounded) in cases {
            for (strategy, expected) in [
                (SmartCodableOptions.NumberConversionStrategy.strict, strict),
                (.truncate, truncated), (.rounded, rounded)
            ] {
                SmartCodableOptions.numberStrategy = strategy
                let model = try XCTUnwrap(Int8ContractModel.deserialize(from: ["value": text]))
                XCTAssertEqual(model.value, expected, "Int8 text=\(text) strategy=\(strategy)")
            }
        }
        for (text, strict, truncated, rounded) in unsignedCases {
            for (strategy, expected) in [
                (SmartCodableOptions.NumberConversionStrategy.strict, strict),
                (.truncate, truncated), (.rounded, rounded)
            ] {
                SmartCodableOptions.numberStrategy = strategy
                let model = try XCTUnwrap(UInt8ContractModel.deserialize(from: ["value": text]))
                XCTAssertEqual(model.value, expected, "UInt8 text=\(text) strategy=\(strategy)")
            }
        }
    }

    func testExponentAndSubprecisionDecimalDoNotLoseRangeInformation() throws {
        let previous = SmartCodableOptions.numberStrategy
        defer { SmartCodableOptions.numberStrategy = previous }
        let tinyFraction = "-9223372036854775808.00000000000000000000000001"
        let hugeExponent = "1e999999999999999999999"
        let tinyExponent = "1e-999999999999999999999"
        for strategy: SmartCodableOptions.NumberConversionStrategy in [.strict, .truncate, .rounded] {
            SmartCodableOptions.numberStrategy = strategy
            let signed = try XCTUnwrap(Int64ContractModel.deserialize(from: ["value": tinyFraction]))
            XCTAssertEqual(signed.value, strategy == .strict ? 77 : Int64.min,
                           "text=\(tinyFraction) strategy=\(strategy)")
            let tooLarge = try XCTUnwrap(Int8ContractModel.deserialize(from: ["value": hugeExponent]))
            XCTAssertEqual(tooLarge.value, 73)
            let tooSmall = try XCTUnwrap(Int8ContractModel.deserialize(from: ["value": tinyExponent]))
            XCTAssertEqual(tooSmall.value, strategy == .strict ? 73 : 0)
            let zero = try XCTUnwrap(Int8ContractModel.deserialize(from: ["value": "0e999999999999999999999"]))
            XCTAssertEqual(zero.value, 0)
        }
    }
}
