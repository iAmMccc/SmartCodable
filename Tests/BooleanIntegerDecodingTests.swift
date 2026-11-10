import CoreFoundation
import Dispatch
import Foundation
import XCTest
@testable import SmartCodable

/// Regression matrix for the opt-in boolean-to-integer decoding strategy.
/// Every expectation below is a literal; no expectation is produced by an internal converter.
final class BooleanIntegerDecodingTests: XCTestCase {

    // MARK: - Fixtures

    private struct IntSentinel: SmartCodableX {
        var value: Int = 73
    }

    private struct IntegerDefaults: SmartCodableX {
        var int: Int = 73
        var int8: Int8 = 73
        var int16: Int16 = 73
        var int32: Int32 = 73
        var int64: Int64 = 73
        var uint: UInt = 73
        var uint8: UInt8 = 73
        var uint16: UInt16 = 73
        var uint32: UInt32 = 73
        var uint64: UInt64 = 73
    }

    private struct OptionalNilDefault: SmartCodableX {
        var value: Int? = nil
    }

    private struct Optional73Default: SmartCodableX {
        var value: Int? = 73
    }

    private struct NestedHost: SmartCodableX {
        var ints: [Int] = [73]
        var optionals: [Int?] = [73]
        var dict: [String: Int] = ["seed": 73]
        var child: IntSentinel = IntSentinel()
    }

    private struct NonIntegerTargets: SmartCodableX {
        var flag: Bool = false
        var floatValue: Float = -1
        var doubleValue: Double = -1
        var cgFloatValue: CGFloat = -1
        var decimalValue: Decimal = Decimal(-1)
        var text: String = "seed"
    }

    private struct AnyFlagHost: SmartCodableX {
        @SmartAny var flag: Any = false
    }

    private struct CompactHost: SmartCodableX {
        @SmartCompact.Array var ints: [Int] = []
        @SmartCompact.Array var optionals: [Int?] = []
        @SmartCompact.Dictionary var typed: [String: Int] = [:]
        @SmartCompact.Array var children: [IntSentinel] = []
        @SmartCompact.Dictionary var dynamic: [String: Any] = [:]
    }

    private struct CompactBaseline: SmartCodableX {
        @SmartCompact.Array var ints: [Int] = []
    }

    private struct TransformerWins: SmartCodableX {
        var value: Int = 73
        static func mappingForValue() -> [SmartValueTransformer]? {
            [CodingKeys.value <--- FastTransformer<Int, Bool>(fromJSON: { _ in 7 })]
        }
    }

    private struct TransformerFallsThrough: SmartCodableX {
        var value: Int = 73
        static func mappingForValue() -> [SmartValueTransformer]? {
            [CodingKeys.value <--- FastTransformer<Int, Bool>(fromJSON: { _ in nil })]
        }
    }

    // MARK: - Helpers

    private func enabledDecoder() -> SmartJSONDecoder {
        let decoder = SmartJSONDecoder()
        decoder.smartBooleanToIntegerDecodingStrategy = .zeroOrOne
        return decoder
    }

    private func valueJSON(_ token: String) -> Data {
        Data("{\"value\":\(token)}".utf8)
    }

    // MARK: - B2I-01

    /// Characterization first: on the default strategy a JSON boolean is recovered
    /// from the declared default, not silently turned into zero or one.
    func testB2I01_DefaultStrategyCharacterization() throws {
        let decoder = SmartJSONDecoder()
        XCTAssertEqual(try decoder.smartDecode(IntSentinel.self, from: valueJSON("true")).value, 73)
        XCTAssertEqual(try decoder.smartDecode(IntSentinel.self, from: valueJSON("false")).value, 73)
        XCTAssertThrowsError(try decoder.smartDecode(Int.self, from: Data("true".utf8)))
        XCTAssertThrowsError(try decoder.smartDecode(Int.self, from: Data("false".utf8)))
    }

    // MARK: - B2I-02

    func testB2I02_AllTenIntegerTypes() throws {
        let decoder = enabledDecoder()
        let json = Data("[true,false]".utf8)
        XCTAssertEqual(try decoder.smartDecode([Int].self, from: json), [1, 0])
        XCTAssertEqual(try decoder.smartDecode([Int8].self, from: json), [1, 0])
        XCTAssertEqual(try decoder.smartDecode([Int16].self, from: json), [1, 0])
        XCTAssertEqual(try decoder.smartDecode([Int32].self, from: json), [1, 0])
        XCTAssertEqual(try decoder.smartDecode([Int64].self, from: json), [1, 0])
        XCTAssertEqual(try decoder.smartDecode([UInt].self, from: json), [1, 0])
        XCTAssertEqual(try decoder.smartDecode([UInt8].self, from: json), [1, 0])
        XCTAssertEqual(try decoder.smartDecode([UInt16].self, from: json), [1, 0])
        XCTAssertEqual(try decoder.smartDecode([UInt32].self, from: json), [1, 0])
        XCTAssertEqual(try decoder.smartDecode([UInt64].self, from: json), [1, 0])
    }

    func testB2I02_AllTenIntegerPropertyDefaults() throws {
        let cases: [(token: String, enabled: Int)] = [("true", 1), ("false", 0)]
        for (token, enabled) in cases {
            let json = Data("""
                {"int":\(token),"int8":\(token),"int16":\(token),"int32":\(token),"int64":\(token),\
                "uint":\(token),"uint8":\(token),"uint16":\(token),"uint32":\(token),"uint64":\(token)}
                """.utf8)
            let legacy = try SmartJSONDecoder().smartDecode(IntegerDefaults.self, from: json)
            let converted = try enabledDecoder().smartDecode(IntegerDefaults.self, from: json)
            for (model, expected, strategy) in [(legacy, 73, "legacy"), (converted, enabled, "zeroOrOne")] {
                let message = "\(strategy), JSON \(token)"
                XCTAssertEqual(model.int, expected, "Int: \(message)")
                XCTAssertEqual(model.int8, Int8(expected), "Int8: \(message)")
                XCTAssertEqual(model.int16, Int16(expected), "Int16: \(message)")
                XCTAssertEqual(model.int32, Int32(expected), "Int32: \(message)")
                XCTAssertEqual(model.int64, Int64(expected), "Int64: \(message)")
                XCTAssertEqual(model.uint, UInt(expected), "UInt: \(message)")
                XCTAssertEqual(model.uint8, UInt8(expected), "UInt8: \(message)")
                XCTAssertEqual(model.uint16, UInt16(expected), "UInt16: \(message)")
                XCTAssertEqual(model.uint32, UInt32(expected), "UInt32: \(message)")
                XCTAssertEqual(model.uint64, UInt64(expected), "UInt64: \(message)")
            }
        }
    }

    func testB2I02_OptionalDefaultsAndMissingOrNull() throws {
        let legacy = SmartJSONDecoder()
        for token in ["true", "false"] {
            XCTAssertNil(try legacy.smartDecode(OptionalNilDefault.self, from: valueJSON(token)).value, token)
            XCTAssertEqual(try legacy.smartDecode(Optional73Default.self, from: valueJSON(token)).value, 73, token)
        }

        let decoder = enabledDecoder()
        XCTAssertEqual(try decoder.smartDecode(OptionalNilDefault.self, from: valueJSON("true")).value, Optional(1))
        XCTAssertEqual(try decoder.smartDecode(OptionalNilDefault.self, from: valueJSON("false")).value, Optional(0))
        XCTAssertEqual(try decoder.smartDecode(Optional73Default.self, from: valueJSON("true")).value, Optional(1))
        XCTAssertEqual(try decoder.smartDecode(Optional73Default.self, from: valueJSON("false")).value, Optional(0))

        let missing = Data("{}".utf8)
        let explicitNull = valueJSON("null")
        for decoder in [SmartJSONDecoder(), enabledDecoder()] {
            XCTAssertNil(try decoder.smartDecode(OptionalNilDefault.self, from: missing).value)
            XCTAssertNil(try decoder.smartDecode(OptionalNilDefault.self, from: explicitNull).value)
            XCTAssertEqual(try decoder.smartDecode(Optional73Default.self, from: missing).value, Optional(73))
            XCTAssertEqual(try decoder.smartDecode(Optional73Default.self, from: explicitNull).value, Optional(73))
        }
    }

    // MARK: - B2I-03

    func testB2I03_ThreeInputEntries() throws {
        let enabled = enabledDecoder()
        let legacy = SmartJSONDecoder()
        let data = valueJSON("true")
        let objectJSON = "{\"value\":true}"
        let dictionary: [String: Any] = ["value": true]

        XCTAssertEqual(try enabled.smartDecode(IntSentinel.self, from: data).value, 1)
        XCTAssertEqual(try enabled.smartDecode(IntSentinel.self, from: objectJSON).value, 1)
        XCTAssertEqual(try enabled.smartDecode(IntSentinel.self, from: dictionary).value, 1)
        XCTAssertEqual(try legacy.smartDecode(IntSentinel.self, from: data).value, 73)
        XCTAssertEqual(try legacy.smartDecode(IntSentinel.self, from: objectJSON).value, 73)
        XCTAssertEqual(try legacy.smartDecode(IntSentinel.self, from: dictionary).value, 73)
    }

    // MARK: - B2I-04

    func testB2I04_RootFragmentAndTopLevelStringRejection() throws {
        let decoder = enabledDecoder()
        XCTAssertEqual(try decoder.smartDecode(Int.self, from: Data("true".utf8)), 1)
        XCTAssertEqual(try decoder.smartDecode(Int.self, from: Data("false".utf8)), 0)
        XCTAssertThrowsError(try decoder.smartDecode(Int.self, from: "true"))
        XCTAssertThrowsError(try decoder.smartDecode(Int.self, from: "false"))
    }

    // MARK: - B2I-05

    func testB2I05_CollectionsAndNestedPropagation() throws {
        let json = Data("{\"ints\":[true,false,2],\"optionals\":[true,false,null,5],\"dict\":{\"a\":true,\"b\":false,\"c\":3},\"child\":{\"value\":true}}".utf8)

        let enabled = try enabledDecoder().smartDecode(NestedHost.self, from: json)
        XCTAssertEqual(enabled.ints, [1, 0, 2])
        XCTAssertEqual(enabled.optionals, [1, 0, nil, 5])
        XCTAssertEqual(enabled.dict, ["a": 1, "b": 0, "c": 3])
        XCTAssertEqual(enabled.child.value, 1)

        let disabled = try SmartJSONDecoder().smartDecode(NestedHost.self, from: json)
        XCTAssertEqual(disabled.ints, [73])
        XCTAssertEqual(disabled.optionals, [73])
        XCTAssertEqual(disabled.dict, ["seed": 73])
        XCTAssertEqual(disabled.child.value, 73)
    }

    // MARK: - B2I-06

    func testB2I06_UnkeyedCursorPrimitiveAndGenericSingleConsumption() throws {
        let json = Data("[true,99]".utf8)

        let primitiveEnabled = try enabledDecoder().smartDecode(PrimitiveCursor.self, from: json)
        XCTAssertEqual(primitiveEnabled.first, 1)
        XCTAssertEqual(primitiveEnabled.indexAfterFirst, 1)
        XCTAssertEqual(primitiveEnabled.trailing, 99)
        XCTAssertTrue(primitiveEnabled.ended)

        let primitiveDisabled = try SmartJSONDecoder().smartDecode(PrimitiveCursor.self, from: json)
        XCTAssertEqual(primitiveDisabled.first, 0)
        XCTAssertEqual(primitiveDisabled.indexAfterFirst, 1)
        XCTAssertEqual(primitiveDisabled.trailing, 99)
        XCTAssertTrue(primitiveDisabled.ended)

        let optionalEnabled = try enabledDecoder().smartDecode(PrimitiveOptionalCursor.self, from: json)
        XCTAssertEqual(optionalEnabled.first, Optional(1))
        XCTAssertEqual(optionalEnabled.indexAfterFirst, 1)
        XCTAssertEqual(optionalEnabled.trailing, 99)
        XCTAssertTrue(optionalEnabled.ended)

        let optionalDisabled = try SmartJSONDecoder().smartDecode(PrimitiveOptionalCursor.self, from: json)
        XCTAssertNil(optionalDisabled.first)
        XCTAssertEqual(optionalDisabled.indexAfterFirst, 1)
        XCTAssertEqual(optionalDisabled.trailing, 99)
        XCTAssertTrue(optionalDisabled.ended)

        let genericEnabled = try enabledDecoder().smartDecode(BoxCursor.self, from: json)
        XCTAssertEqual(genericEnabled.first, 1)
        XCTAssertEqual(genericEnabled.indexAfterFirst, 1)
        XCTAssertEqual(genericEnabled.trailing, 99)
        XCTAssertTrue(genericEnabled.ended)

        let genericOptionalEnabled = try enabledDecoder().smartDecode(BoxOptionalCursor.self, from: json)
        XCTAssertEqual(genericOptionalEnabled.first, Optional(1))
        XCTAssertEqual(genericOptionalEnabled.indexAfterFirst, 1)
        XCTAssertEqual(genericOptionalEnabled.trailing, 99)
        XCTAssertTrue(genericOptionalEnabled.ended)
    }

    func testB2I06_UnkeyedPreservesNullInvalidAndEOFRules() throws {
        let nullJSON = Data("[null,99]".utf8)
        let invalidJSON = Data("[\"bad\",99]".utf8)
        let emptyJSON = Data("[]".utf8)

        for decoder in [SmartJSONDecoder(), enabledDecoder()] {
            let nullCursor = try decoder.smartDecode(PrimitiveOptionalCursor.self, from: nullJSON)
            XCTAssertNil(nullCursor.first)
            XCTAssertEqual(nullCursor.indexAfterFirst, 1)
            XCTAssertEqual(nullCursor.trailing, 99)
            XCTAssertTrue(nullCursor.ended)

            let invalidCursor = try decoder.smartDecode(PrimitiveOptionalCursor.self, from: invalidJSON)
            XCTAssertNil(invalidCursor.first)
            XCTAssertEqual(invalidCursor.indexAfterFirst, 1)
            XCTAssertEqual(invalidCursor.trailing, 99)
            XCTAssertTrue(invalidCursor.ended)
        }

        let cases: [(SmartJSONDecoder.UnkeyedDecodingStrategy, Int, Int)] = [
            (.legacy, 1, 2),
            (.consumeOnce, 0, 0)
        ]
        for (unkeyed, primitiveOptionalIndex, genericOptionalIndex) in cases {
            for boolean: SmartJSONDecoder.BooleanToIntegerDecodingStrategy in [.legacy, .zeroOrOne] {
                let decoder = SmartJSONDecoder()
                decoder.smartUnkeyedDecodingStrategy = unkeyed
                decoder.smartBooleanToIntegerDecodingStrategy = boolean
                let eof = try decoder.smartDecode(EOFCursor.self, from: emptyJSON)
                let message = "unkeyed \(unkeyed), boolean \(boolean)"
                XCTAssertEqual(eof.typed, 0, message)
                XCTAssertEqual(eof.typedIndex, 1, message)
                XCTAssertTrue(eof.typedAtEnd, message)
                XCTAssertNil(eof.present, message)
                XCTAssertEqual(eof.presentIndex, primitiveOptionalIndex, message)
                XCTAssertTrue(eof.presentAtEnd, message)
                XCTAssertNil(eof.generic, message)
                XCTAssertTrue(eof.genericValueNotFound, message)
                XCTAssertEqual(eof.genericIndex, 0, message)
                XCTAssertTrue(eof.genericAtEnd, message)
                XCTAssertNil(eof.genericPresent, message)
                XCTAssertEqual(eof.genericPresentIndex, genericOptionalIndex, message)
                XCTAssertTrue(eof.genericPresentAtEnd, message)
            }
        }
    }

    func testB2I06_UnkeyedBooleanSuccessAcrossCursorStrategies() throws {
        let cases: [(String, Int)] = [("true", 1), ("false", 0)]
        for unkeyed: SmartJSONDecoder.UnkeyedDecodingStrategy in [.legacy, .consumeOnce] {
            let decoder = enabledDecoder()
            decoder.smartUnkeyedDecodingStrategy = unkeyed
            for (token, expected) in cases {
                let json = Data("[\(token),99]".utf8)
                let message = "unkeyed \(unkeyed), JSON \(token)"
                let primitive = try decoder.smartDecode(PrimitiveCursor.self, from: json)
                XCTAssertEqual(primitive.first, expected, message)
                XCTAssertEqual(primitive.indexAfterFirst, 1, message)
                XCTAssertEqual(primitive.trailing, 99, message)
                XCTAssertEqual(primitive.finalIndex, 2, message)
                XCTAssertTrue(primitive.ended, message)

                let primitiveOptional = try decoder.smartDecode(PrimitiveOptionalCursor.self, from: json)
                XCTAssertEqual(primitiveOptional.first, expected, message)
                XCTAssertEqual(primitiveOptional.indexAfterFirst, 1, message)
                XCTAssertEqual(primitiveOptional.trailing, 99, message)
                XCTAssertEqual(primitiveOptional.finalIndex, 2, message)
                XCTAssertTrue(primitiveOptional.ended, message)

                let generic = try decoder.smartDecode(BoxCursor.self, from: json)
                XCTAssertEqual(generic.first, expected, message)
                XCTAssertEqual(generic.indexAfterFirst, 1, message)
                XCTAssertEqual(generic.trailing, 99, message)
                XCTAssertEqual(generic.finalIndex, 2, message)
                XCTAssertTrue(generic.ended, message)

                let genericOptional = try decoder.smartDecode(BoxOptionalCursor.self, from: json)
                XCTAssertEqual(genericOptional.first, expected, message)
                XCTAssertEqual(genericOptional.indexAfterFirst, 1, message)
                XCTAssertEqual(genericOptional.trailing, 99, message)
                XCTAssertEqual(genericOptional.finalIndex, 2, message)
                XCTAssertTrue(genericOptional.ended, message)
            }
        }
    }

    func testB2I06_GenericOptionalInvalidAndNullKeepCursorContracts() throws {
        let cases: [(SmartJSONDecoder.UnkeyedDecodingStrategy, Int, Int, Int, Bool)] = [
            (.legacy, 2, 77, 3, true),
            (.consumeOnce, 1, 99, 2, false)
        ]
        for (unkeyed, firstIndex, trailing, finalIndex, ended) in cases {
            for boolean: SmartJSONDecoder.BooleanToIntegerDecodingStrategy in [.legacy, .zeroOrOne] {
                let decoder = SmartJSONDecoder()
                decoder.smartUnkeyedDecodingStrategy = unkeyed
                decoder.smartBooleanToIntegerDecodingStrategy = boolean
                for token in ["null", "\"bad\""] {
                    let probe = try decoder.smartDecode(GenericBoundaryCursor.self, from: Data("[\(token),99,77]".utf8))
                    let message = "unkeyed \(unkeyed), boolean \(boolean), JSON \(token)"
                    XCTAssertNil(probe.first, message)
                    XCTAssertEqual(probe.indexAfterFirst, firstIndex, message)
                    XCTAssertEqual(probe.trailing, trailing, message)
                    XCTAssertEqual(probe.finalIndex, finalIndex, message)
                    XCTAssertEqual(probe.ended, ended, message)
                }
            }
        }
    }

    // MARK: - B2I-07

    func testB2I07_NonBooleanFormsNeverBecomeIntegers() throws {
        let payloads: [Any] = [
            Data("{}".utf8),
            valueJSON("null"),
            valueJSON("{}"),
            valueJSON("[]"),
            valueJSON("\"true\""),
            valueJSON("\"false\""),
            valueJSON("\"YES\"")
        ]
        for payload in payloads {
            XCTAssertEqual(try enabledDecoder().smartDecode(IntSentinel.self, from: payload).value, 73)
            XCTAssertEqual(try SmartJSONDecoder().smartDecode(IntSentinel.self, from: payload).value, 73)
        }
    }

    // MARK: - B2I-08

    func testB2I08_FieldTransformerPriorityAndFallthrough() throws {
        let trueJSON = valueJSON("true")
        let falseJSON = valueJSON("false")

        for decoder in [SmartJSONDecoder(), enabledDecoder()] {
            XCTAssertEqual(try decoder.smartDecode(TransformerWins.self, from: trueJSON).value, 7)
            XCTAssertEqual(try decoder.smartDecode(TransformerWins.self, from: falseJSON).value, 7)
        }

        XCTAssertEqual(try enabledDecoder().smartDecode(TransformerFallsThrough.self, from: trueJSON).value, 1)
        XCTAssertEqual(try enabledDecoder().smartDecode(TransformerFallsThrough.self, from: falseJSON).value, 0)
        XCTAssertEqual(try SmartJSONDecoder().smartDecode(TransformerFallsThrough.self, from: trueJSON).value, 73)
        XCTAssertEqual(try SmartJSONDecoder().smartDecode(TransformerFallsThrough.self, from: falseJSON).value, 73)
    }

    // MARK: - B2I-09

    func testB2I09_DecoderIsolationAndFixedConfigConcurrency() throws {
        let enabled = enabledDecoder()
        let legacy = SmartJSONDecoder()
        XCTAssertEqual(try enabled.smartDecode(IntSentinel.self, from: valueJSON("true")).value, 1)
        XCTAssertEqual(try legacy.smartDecode(IntSentinel.self, from: valueJSON("true")).value, 73)
        XCTAssertEqual(try enabled.smartDecode(IntSentinel.self, from: valueJSON("false")).value, 0)
        XCTAssertEqual(try legacy.smartDecode(IntSentinel.self, from: valueJSON("false")).value, 73)
        XCTAssertEqual(try enabled.smartDecode(IntSentinel.self, from: valueJSON("true")).value, 1)
        XCTAssertEqual(try legacy.smartDecode(IntSentinel.self, from: valueJSON("false")).value, 73)

        let nested = Data("{\"ints\":[true,false,2],\"optionals\":[true,false,null,5],\"dict\":{\"a\":true,\"b\":false,\"c\":3},\"child\":{\"value\":true}}".utf8)
        XCTAssertEqual(try enabled.smartDecode(NestedHost.self, from: nested).child.value, 1)
        XCTAssertEqual(try legacy.smartDecode(NestedHost.self, from: nested).child.value, 73)

        let lock = NSLock()
        var failures: [String] = []
        let makeJSON: (String) -> Data = { Data("{\"value\":\($0)}".utf8) }
        DispatchQueue.concurrentPerform(iterations: 100) { index in
            let on = SmartJSONDecoder()
            on.smartBooleanToIntegerDecodingStrategy = .zeroOrOne
            let off = SmartJSONDecoder()
            let even = index % 2 == 0
            let payload = makeJSON(even ? "true" : "false")
            let expected = even ? 1 : 0
            do {
                let enabledValue = try on.smartDecode(IntSentinel.self, from: payload).value
                let legacyValue = try off.smartDecode(IntSentinel.self, from: payload).value
                if enabledValue != expected || legacyValue != 73 {
                    lock.lock()
                    failures.append("iteration \(index): \(enabledValue)/\(legacyValue)")
                    lock.unlock()
                }
            } catch {
                lock.lock()
                failures.append("iteration \(index): \(error)")
                lock.unlock()
            }
        }
        XCTAssertEqual(failures, [])
    }

    // MARK: - B2I-10

    func testB2I10_CompactElementBaselinesArePreserved() throws {
        let json: [String: Any] = ["ints": [1, "2", "bad", NSNull(), 3.5, true] as [Any]]
        let previous = SmartCodableOptions.compactElementStrategy
        defer { SmartCodableOptions.compactElementStrategy = previous }

        SmartCodableOptions.compactElementStrategy = .legacy
        XCTAssertEqual(try SmartJSONDecoder().smartDecode(CompactBaseline.self, from: json).ints, [1, 1])
        SmartCodableOptions.compactElementStrategy = .convert
        XCTAssertEqual(try SmartJSONDecoder().smartDecode(CompactBaseline.self, from: json).ints, [1, 2])
    }

    func testB2I10_CompactOptionalTypedDictionaryAndModelElements() throws {
        let json: [String: Any] = [
            "ints": [true, false, 2] as [Any],
            "optionals": [true, false, NSNull(), 5] as [Any],
            "typed": ["a": true, "b": false, "c": 3] as [String: Any],
            "children": [["value": true], ["value": false]] as [Any]
        ]
        let previous = SmartCodableOptions.compactElementStrategy
        defer { SmartCodableOptions.compactElementStrategy = previous }

        for strategy in [SmartCodableOptions.CompactElementStrategy.legacy, .convert] {
            SmartCodableOptions.compactElementStrategy = strategy
            let host = try enabledDecoder().smartDecode(CompactHost.self, from: json)
            XCTAssertEqual(host.ints, [1, 0, 2])
            XCTAssertEqual(host.optionals, [1, 0, 5])
            XCTAssertEqual(host.typed, ["a": 1, "b": 0, "c": 3])
            XCTAssertEqual(host.children.map(\.value), [1, 0])
        }

        let disabled = try SmartJSONDecoder().smartDecode(CompactHost.self, from: json)
        XCTAssertEqual(disabled.children.map(\.value), [73, 73])
    }

    func testB2I10_CompactStrategyMatrixWithDynamicValues() throws {
        let json = Data("""
            {"ints":[true,false,2],"optionals":[true,false,null,5],\
            "typed":{"a":true,"b":false,"c":3},\
            "children":[{"value":true},{"value":false}],\
            "dynamic":{"a":true,"b":false,"c":3}}
            """.utf8)
        let previous = SmartCodableOptions.compactElementStrategy
        defer { SmartCodableOptions.compactElementStrategy = previous }

        let cases: [(SmartCodableOptions.CompactElementStrategy,
                     SmartJSONDecoder.BooleanToIntegerDecodingStrategy,
                     [Int], [String: Int], [Int])] = [
            (.legacy, .legacy, [1, 0, 2], ["c": 3], [73, 73]),
            (.legacy, .zeroOrOne, [1, 0, 2], ["a": 1, "b": 0, "c": 3], [1, 0]),
            (.convert, .legacy, [2], ["c": 3], [73, 73]),
            (.convert, .zeroOrOne, [1, 0, 2], ["a": 1, "b": 0, "c": 3], [1, 0])
        ]
        for (compact, boolean, expectedInts, expectedTyped, expectedChildren) in cases {
            SmartCodableOptions.compactElementStrategy = compact
            let decoder = SmartJSONDecoder()
            decoder.smartBooleanToIntegerDecodingStrategy = boolean
            let host = try decoder.smartDecode(CompactHost.self, from: json)
            let message = "compact \(compact), boolean \(boolean)"
            XCTAssertEqual(host.ints, expectedInts, message)
            XCTAssertEqual(host.optionals, [1, 0, 5], message)
            XCTAssertEqual(host.typed, expectedTyped, message)
            XCTAssertEqual(host.children.map(\.value), expectedChildren, message)
            XCTAssertEqual(host.dynamic.count, 3, message)
            for (key, expected) in [("a", true), ("b", false)] {
                let flag = try XCTUnwrap(host.dynamic[key] as? NSNumber, message)
                XCTAssertEqual(CFGetTypeID(flag), CFBooleanGetTypeID(), message)
                XCTAssertEqual(flag.boolValue, expected, message)
            }
            let number = try XCTUnwrap(host.dynamic["c"] as? NSNumber, message)
            XCTAssertNotEqual(CFGetTypeID(number), CFBooleanGetTypeID(), message)
            XCTAssertEqual(number.intValue, 3, message)
        }
    }

    // MARK: - B2I-11

    func testB2I11_SmartAnyBooleanIdentitySurvivesBothStrategies() throws {
        let cases: [(String, Bool)] = [("true", true), ("false", false)]
        for decoder in [SmartJSONDecoder(), enabledDecoder()] {
            for (token, expected) in cases {
                let model = try decoder.smartDecode(AnyFlagHost.self, from: Data("{\"flag\":\(token)}".utf8))
                let decoded = try XCTUnwrap(model.flag as? NSNumber)
                XCTAssertEqual(CFGetTypeID(decoded), CFBooleanGetTypeID())
                XCTAssertEqual(decoded.boolValue, expected)

                let data = try SmartJSONEncoder().encode(model)
                let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
                let encoded = try XCTUnwrap(object["flag"] as? NSNumber)
                XCTAssertEqual(CFGetTypeID(encoded), CFBooleanGetTypeID())
                XCTAssertEqual(encoded.boolValue, expected)

                let text = try XCTUnwrap(String(data: data, encoding: .utf8))
                XCTAssertTrue(text.contains("\"flag\":\(token)"))
                XCTAssertFalse(text.contains("\"flag\":1"))
                XCTAssertFalse(text.contains("\"flag\":0"))
            }
        }
    }

    // MARK: - B2I-12

    func testB2I12_NonIntegerTargetsAreUnchanged() throws {
        let normal = Data("{\"flag\":true,\"floatValue\":2.5,\"doubleValue\":3.5,\"cgFloatValue\":4.5,\"decimalValue\":9,\"text\":\"text\"}".utf8)
        let allBooleans = Data("{\"flag\":true,\"floatValue\":true,\"doubleValue\":true,\"cgFloatValue\":true,\"decimalValue\":true,\"text\":true}".utf8)

        for decoder in [SmartJSONDecoder(), enabledDecoder()] {
            let decoded = try decoder.smartDecode(NonIntegerTargets.self, from: normal)
            XCTAssertTrue(decoded.flag)
            XCTAssertEqual(decoded.floatValue, 2.5)
            XCTAssertEqual(decoded.doubleValue, 3.5)
            XCTAssertEqual(decoded.cgFloatValue, 4.5)
            XCTAssertEqual(decoded.decimalValue, Decimal(9))
            XCTAssertEqual(decoded.text, "text")

            let bools = try decoder.smartDecode(NonIntegerTargets.self, from: allBooleans)
            XCTAssertTrue(bools.flag)
            XCTAssertEqual(bools.floatValue, -1)
            XCTAssertEqual(bools.doubleValue, -1)
            XCTAssertEqual(bools.cgFloatValue, -1)
            XCTAssertEqual(bools.decimalValue, Decimal(-1))
            XCTAssertEqual(bools.text, "seed")
        }
    }

    // MARK: - B2I-13

    func testB2I13_NumberStrategyModesDoNotChangeBooleanMapping() throws {
        let previous = SmartCodableOptions.numberStrategy
        defer { SmartCodableOptions.numberStrategy = previous }
        for strategy: SmartCodableOptions.NumberConversionStrategy in [.strict, .truncate, .rounded] {
            SmartCodableOptions.numberStrategy = strategy
            let decoder = enabledDecoder()
            XCTAssertEqual(try decoder.smartDecode(IntSentinel.self, from: valueJSON("true")).value, 1)
            XCTAssertEqual(try decoder.smartDecode(IntSentinel.self, from: valueJSON("false")).value, 0)
        }
    }
}

// MARK: - Hand-written unkeyed cursors

private struct PrimitiveCursor: Decodable {
    var first: Int = -1
    var indexAfterFirst: Int = -1
    var trailing: Int = -1
    var finalIndex: Int = -1
    var ended: Bool = false

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        first = try container.decode(Int.self)
        indexAfterFirst = container.currentIndex
        trailing = try container.decode(Int.self)
        finalIndex = container.currentIndex
        ended = container.isAtEnd
    }
}

private struct PrimitiveOptionalCursor: Decodable {
    var first: Int? = nil
    var indexAfterFirst: Int = -1
    var trailing: Int = -1
    var finalIndex: Int = -1
    var ended: Bool = false

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        first = try container.decodeIfPresent(Int.self)
        indexAfterFirst = container.currentIndex
        trailing = try container.decode(Int.self)
        finalIndex = container.currentIndex
        ended = container.isAtEnd
    }
}

private struct BoxValue: Decodable {
    var value: Int = -1

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(Int.self)
    }
}

private struct BoxCursor: Decodable {
    var first: Int = -1
    var indexAfterFirst: Int = -1
    var trailing: Int = -1
    var finalIndex: Int = -1
    var ended: Bool = false

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let box = try container.decode(BoxValue.self)
        first = box.value
        indexAfterFirst = container.currentIndex
        trailing = try container.decode(Int.self)
        finalIndex = container.currentIndex
        ended = container.isAtEnd
    }
}

private struct BoxOptionalCursor: Decodable {
    var first: Int? = nil
    var indexAfterFirst: Int = -1
    var trailing: Int = -1
    var finalIndex: Int = -1
    var ended: Bool = false

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let box = try container.decodeIfPresent(BoxValue.self)
        first = box?.value
        indexAfterFirst = container.currentIndex
        trailing = try container.decode(Int.self)
        finalIndex = container.currentIndex
        ended = container.isAtEnd
    }
}

private struct PositiveBox: Decodable {
    let value: Int

    init(from decoder: Decoder) throws {
        value = try decoder.singleValueContainer().decode(Int.self)
        guard value > 0 else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "positive required"))
        }
    }
}

private struct GenericBoundaryCursor: Decodable {
    let first: Int?
    let indexAfterFirst: Int
    let trailing: Int
    let finalIndex: Int
    let ended: Bool

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        first = try container.decodeIfPresent(PositiveBox.self)?.value
        indexAfterFirst = container.currentIndex
        trailing = try container.decode(Int.self)
        finalIndex = container.currentIndex
        ended = container.isAtEnd
    }
}

private struct EOFCursor: Decodable {
    let typed: Int
    let typedIndex: Int
    let typedAtEnd: Bool
    let present: Int?
    let presentIndex: Int
    let presentAtEnd: Bool
    let generic: Int?
    let genericValueNotFound: Bool
    let genericIndex: Int
    let genericAtEnd: Bool
    let genericPresent: Int?
    let genericPresentIndex: Int
    let genericPresentAtEnd: Bool

    init(from decoder: Decoder) throws {
        var primitive = try decoder.unkeyedContainer()
        typed = try primitive.decode(Int.self)
        typedIndex = primitive.currentIndex
        typedAtEnd = primitive.isAtEnd

        var primitiveOptional = try decoder.unkeyedContainer()
        present = try primitiveOptional.decodeIfPresent(Int.self)
        presentIndex = primitiveOptional.currentIndex
        presentAtEnd = primitiveOptional.isAtEnd

        var genericContainer = try decoder.unkeyedContainer()
        do {
            generic = try genericContainer.decode(BoxValue.self).value
            genericValueNotFound = false
        } catch DecodingError.valueNotFound(let type, _) where type == BoxValue.self {
            generic = nil
            genericValueNotFound = true
        }
        genericIndex = genericContainer.currentIndex
        genericAtEnd = genericContainer.isAtEnd

        var genericOptional = try decoder.unkeyedContainer()
        genericPresent = try genericOptional.decodeIfPresent(BoxValue.self)?.value
        genericPresentIndex = genericOptional.currentIndex
        genericPresentAtEnd = genericOptional.isAtEnd
    }
}
