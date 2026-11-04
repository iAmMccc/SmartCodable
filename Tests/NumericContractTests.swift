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

private struct BoolDefaultTrueContractModel: SmartCodableX {
    var value: Bool = true
}

private struct Int64ContractModel: SmartCodableX {
    var value: Int64 = 77
}

private struct UInt64ContractModel: SmartCodableX {
    var value: UInt64 = 99
}

private struct IntContractModel: SmartCodableX {
    var value: Int = 77
}

private struct Int16ContractModel: SmartCodableX {
    var value: Int16 = 77
}

private struct Int32ContractModel: SmartCodableX {
    var value: Int32 = 77
}

private struct UIntContractModel: SmartCodableX {
    var value: UInt = 99
}

private struct UInt16ContractModel: SmartCodableX {
    var value: UInt16 = 99
}

private struct UInt32ContractModel: SmartCodableX {
    var value: UInt32 = 99
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

    /// 18 种接受形式 × 默认 false/true，非法输入回落到各自声明默认值。
    func testEveryBoolFormAgainstBothDefaults() throws {
        let accepted: [(Any, Bool)] = [
            (true, true),
            (false, false),
            (1, true),
            (0, false),
            ("1", true), ("YES", true), ("Yes", true), ("yes", true),
            ("TRUE", true), ("True", true), ("true", true),
            ("0", false), ("NO", false), ("No", false), ("no", false),
            ("FALSE", false), ("False", false), ("false", false)
        ]
        let invalid: [Any] = [2, -1, "maybe", "", "Y", "on"]
        var acceptedCases = 0
        var invalidCases = 0

        for (input, expected) in accepted {
            let falseDefault = try XCTUnwrap(
                BoolContractModel.deserialize(from: ["value": input]),
                "default false input=\(input)"
            )
            XCTAssertEqual(falseDefault.value, expected, "default false input=\(input)")
            acceptedCases += 1

            let trueDefault = try XCTUnwrap(
                BoolDefaultTrueContractModel.deserialize(from: ["value": input]),
                "default true input=\(input)"
            )
            XCTAssertEqual(trueDefault.value, expected, "default true input=\(input)")
            acceptedCases += 1
        }

        for input in invalid {
            let falseDefault = try XCTUnwrap(
                BoolContractModel.deserialize(from: ["value": input]),
                "invalid default false input=\(input)"
            )
            XCTAssertEqual(falseDefault.value, false, "invalid default false input=\(input)")
            invalidCases += 1

            let trueDefault = try XCTUnwrap(
                BoolDefaultTrueContractModel.deserialize(from: ["value": input]),
                "invalid default true input=\(input)"
            )
            XCTAssertEqual(trueDefault.value, true, "invalid default true input=\(input)")
            invalidCases += 1
        }

        XCTAssertEqual(acceptedCases, 36)
        XCTAssertEqual(invalidCases, 12)
    }

    /// Int/Int16/Int32/UInt/UInt16/UInt32 × 边界四点 × 字符串与 JSON 数字 × 三种策略。
    func testRemainingFixedWidthIntegerBoundariesByRepresentationAndPolicy() throws {
        let previous = SmartCodableOptions.numberStrategy
        defer { SmartCodableOptions.numberStrategy = previous }

        XCTAssertEqual(Int.bitWidth, 64)
        XCTAssertEqual(UInt.bitWidth, 64)
        XCTAssertEqual(String(Int.min), "-9223372036854775808")
        XCTAssertEqual(String(Int.max), "9223372036854775807")
        XCTAssertEqual(String(UInt.max), "18446744073709551615")
        XCTAssertEqual(String(Int16.min), "-32768")
        XCTAssertEqual(String(Int16.max), "32767")
        XCTAssertEqual(String(Int32.min), "-2147483648")
        XCTAssertEqual(String(Int32.max), "2147483647")
        XCTAssertEqual(String(UInt16.max), "65535")
        XCTAssertEqual(String(UInt32.max), "4294967295")

        let policies: [SmartCodableOptions.NumberConversionStrategy] = [.strict, .truncate, .rounded]
        var cases = 0

        func check<Model: SmartCodableX, Bits: FixedWidthInteger>(
            _: Model.Type,
            _: Bits.Type,
            fallback: Bits,
            minimum: String,
            maximum: String,
            belowMinimum: String,
            aboveMaximum: String,
            value: (Model) -> Bits
        ) throws {
            let samples: [(String, Bits)] = [
                (minimum, Bits.min),
                (maximum, Bits.max),
                (belowMinimum, fallback),
                (aboveMaximum, fallback)
            ]
            for policy in policies {
                SmartCodableOptions.numberStrategy = policy
                for (text, expected) in samples {
                    let fromString = try XCTUnwrap(
                        Model.deserialize(from: ["value": text]),
                        "string \(Bits.self) policy=\(policy) text=\(text)"
                    )
                    XCTAssertEqual(
                        value(fromString),
                        expected,
                        "string \(Bits.self) policy=\(policy) text=\(text)"
                    )
                    cases += 1

                    let data = Data("{\"value\":\(text)}".utf8)
                    let fromNumber = try XCTUnwrap(
                        Model.deserialize(from: data),
                        "number \(Bits.self) policy=\(policy) text=\(text)"
                    )
                    XCTAssertEqual(
                        value(fromNumber),
                        expected,
                        "number \(Bits.self) policy=\(policy) text=\(text)"
                    )
                    cases += 1
                }
            }
        }

        try check(
            IntContractModel.self, Int.self, fallback: 77,
            minimum: "-9223372036854775808",
            maximum: "9223372036854775807",
            belowMinimum: "-9223372036854775809",
            aboveMaximum: "9223372036854775808",
            value: { $0.value }
        )
        try check(
            Int16ContractModel.self, Int16.self, fallback: 77,
            minimum: "-32768",
            maximum: "32767",
            belowMinimum: "-32769",
            aboveMaximum: "32768",
            value: { $0.value }
        )
        try check(
            Int32ContractModel.self, Int32.self, fallback: 77,
            minimum: "-2147483648",
            maximum: "2147483647",
            belowMinimum: "-2147483649",
            aboveMaximum: "2147483648",
            value: { $0.value }
        )
        try check(
            UIntContractModel.self, UInt.self, fallback: 99,
            minimum: "0",
            maximum: "18446744073709551615",
            belowMinimum: "-1",
            aboveMaximum: "18446744073709551616",
            value: { $0.value }
        )
        try check(
            UInt16ContractModel.self, UInt16.self, fallback: 99,
            minimum: "0",
            maximum: "65535",
            belowMinimum: "-1",
            aboveMaximum: "65536",
            value: { $0.value }
        )
        try check(
            UInt32ContractModel.self, UInt32.self, fallback: 99,
            minimum: "0",
            maximum: "4294967295",
            belowMinimum: "-1",
            aboveMaximum: "4294967296",
            value: { $0.value }
        )

        XCTAssertEqual(cases, 144)
    }

    /// "±12.d"（d = 0...9）× strict/truncate/rounded。strict 在 d == 0 时接受该整数，否则回退 77。
    func testTwelvePointDigitRoundingByStrategy() throws {
        let previous = SmartCodableOptions.numberStrategy
        defer { SmartCodableOptions.numberStrategy = previous }

        var matrixCases = 0
        for negative in [false, true] {
            for digit in 0...9 {
                let text = (negative ? "-" : "") + "12.\(digit)"
                let truncated = negative ? -12 : 12
                let roundedAway = negative ? -13 : 13
                for strategy: SmartCodableOptions.NumberConversionStrategy in [.strict, .truncate, .rounded] {
                    let expected: Int
                    switch strategy {
                    case .truncate:
                        expected = truncated
                    case .rounded:
                        expected = digit >= 5 ? roundedAway : truncated
                    case .strict:
                        expected = digit == 0 ? truncated : 77
                    }
                    SmartCodableOptions.numberStrategy = strategy
                    let model = try XCTUnwrap(
                        IntContractModel.deserialize(from: ["value": text]),
                        "text=\(text) strategy=\(strategy)"
                    )
                    XCTAssertEqual(model.value, expected, "text=\(text) strategy=\(strategy)")
                    matrixCases += 1
                }
            }
        }
        XCTAssertEqual(matrixCases, 60)

        SmartCodableOptions.numberStrategy = .rounded
        let carrySamples: [(String, Int)] = [
            ("9.5", 10),
            ("99.5", 100),
            ("999.5", 1000),
            ("-9.5", -10),
            ("12.05", 12),
            ("12.45", 12)
        ]
        var carryCases = 0
        for (text, expected) in carrySamples {
            let model = try XCTUnwrap(IntContractModel.deserialize(from: ["value": text]), text)
            XCTAssertEqual(model.value, expected, text)
            carryCases += 1
        }
        XCTAssertEqual(carryCases, 6)
    }

    /// strict 接受数值恰好为整数的小数文本；非整数小数仍回退声明默认值 77。
    func testStrictAcceptsIntegralDecimalText() throws {
        let previous = SmartCodableOptions.numberStrategy
        defer { SmartCodableOptions.numberStrategy = previous }
        SmartCodableOptions.numberStrategy = .strict

        struct DataModel: SmartCodableX { var v: Int = 77 }
        let stringSamples = [("12.00", 12), ("1.2e1", 12), ("1e2", 100), ("12.5", 77)]
        let dataSamples = [("{\"v\":12.0}", 12), ("{\"v\":-12.0}", -12), ("{\"v\":1.0e2}", 100)]
        var executed = 0
        for (text, expected) in stringSamples {
            let model = try XCTUnwrap(IntContractModel.deserialize(from: ["value": text]), text)
            XCTAssertEqual(model.value, expected, text)
            executed += 1
        }
        for (json, expected) in dataSamples {
            let model = try XCTUnwrap(DataModel.deserialize(from: Data(json.utf8)), json)
            XCTAssertEqual(model.v, expected, json)
            executed += 1
        }
        XCTAssertEqual(executed, 7)
    }
}
