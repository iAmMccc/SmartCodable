import UIKit
import CoreFoundation
import SmartCodable

/// 对照布尔转整数策略、集合包装器与 Foundation 数字类型。
final class BooleanIntegerDemoViewController: DemoBaseViewController {
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

    private struct Value: SmartCodableX {
        var value: Int = 73
    }

    private struct OptionalNil: SmartCodableX {
        var value: Int? = nil
    }

    private struct OptionalDefault: SmartCodableX {
        var value: Int? = 73
    }

    private struct Nested: SmartCodableX {
        var ints: [Int] = [73]
        var optionals: [Int?] = [73]
        var dict: [String: Int] = ["seed": 73]
        var child: Value = Value()
    }

    private struct Compact: SmartCodableX {
        @SmartCompact.Array var ints: [Int] = []
        @SmartCompact.Array var optionals: [Int?] = []
        @SmartCompact.Dictionary var typed: [String: Int] = [:]
        @SmartCompact.Array var children: [Value] = []
        @SmartCompact.Dictionary var dynamic: [String: Any] = [:]
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

    override var showsInput: Bool { false }

    override func run(with json: String) -> [String] {
        let previous = SmartCodableOptions.compactElementStrategy
        defer { SmartCodableOptions.compactElementStrategy = previous }

        var report = BooleanIntegerReport()
        integerFields(into: &report)
        inputsAndOptionals(into: &report)
        collections(into: &report)
        compactCollections(into: &report)
        otherValuesAndTransformers(into: &report)
        encodingAndIsolation(into: &report)
        return report.finish()
    }

    private var booleanModes: [(String, SmartJSONDecoder.BooleanToIntegerDecodingStrategy)] {
        [(".legacy（默认）", .legacy), (".zeroOrOne", .zeroOrOne)]
    }

    private func decoder(_ strategy: SmartJSONDecoder.BooleanToIntegerDecodingStrategy) -> SmartJSONDecoder {
        let decoder = SmartJSONDecoder()
        if strategy == .zeroOrOne {
            decoder.smartBooleanToIntegerDecodingStrategy = .zeroOrOne
        }
        return decoder
    }

    private func integerFields(into report: inout BooleanIntegerReport) {
        let fields: [(String, (IntegerDefaults) -> String)] = [
            ("int", { String($0.int) }), ("int8", { String($0.int8) }),
            ("int16", { String($0.int16) }), ("int32", { String($0.int32) }),
            ("int64", { String($0.int64) }), ("uint", { String($0.uint) }),
            ("uint8", { String($0.uint8) }), ("uint16", { String($0.uint16) }),
            ("uint32", { String($0.uint32) }), ("uint64", { String($0.uint64) }),
        ]
        for (token, converted) in [("true", "1"), ("false", "0")] {
            let payload = "{" + fields.map { "\"\($0.0)\":\(token)" }.joined(separator: ",") + "}"
            for (name, strategy) in booleanModes {
                for (field, read) in fields {
                    report.add(input: payload, api: "smartDecode(IntegerDefaults), Bool → Int = \(name), .\(field)",
                               expected: strategy == .legacy ? "73" : converted) {
                        read(try self.decoder(strategy).smartDecode(IntegerDefaults.self, from: Data(payload.utf8)))
                    }
                }
            }
        }
    }

    private func inputsAndOptionals(into report: inout BooleanIntegerReport) {
        for (token, bool, converted) in [("true", true, "1"), ("false", false, "0")] {
            let payload = "{\"value\":\(token)}"
            let sources: [(String, Any)] = [
                ("Data", Data(payload.utf8)), ("String", payload),
                ("Dictionary", ["value": bool] as [String: Any]),
            ]
            for (name, strategy) in booleanModes {
                let expected = strategy == .legacy ? "73" : converted
                for (source, input) in sources {
                    report.add(input: "\(source): \(payload)", api: "smartDecode(Value), Bool → Int = \(name)", expected: expected) {
                        String(try self.decoder(strategy).smartDecode(Value.self, from: input).value)
                    }
                }
                report.add(input: "Data fragment: \(token)", api: "smartDecode(Int), Bool → Int = \(name)",
                           expected: strategy == .legacy ? "抛错" : converted) {
                    String(try self.decoder(strategy).smartDecode(Int.self, from: Data(token.utf8)))
                }
                report.add(input: "String fragment: \(token)", api: "smartDecode(Int), Bool → Int = \(name)", expected: "抛错") {
                    String(try self.decoder(strategy).smartDecode(Int.self, from: token))
                }
            }
        }

        let samples: [(String, String, String, String, String)] = [
            (#"{"value":true}"#, "nil", "73", "1", "1"),
            (#"{"value":false}"#, "nil", "73", "0", "0"),
            (#"{}"#, "nil", "73", "nil", "73"),
            (#"{"value":null}"#, "nil", "73", "nil", "73"),
        ]
        for (payload, legacyNil, legacyDefault, enabledNil, enabledDefault) in samples {
            for (name, strategy) in booleanModes {
                report.add(input: payload, api: "smartDecode(OptionalNil), Bool → Int = \(name)",
                           expected: strategy == .legacy ? legacyNil : enabledNil) {
                    self.optional(try self.decoder(strategy).smartDecode(OptionalNil.self, from: Data(payload.utf8)).value)
                }
                report.add(input: payload, api: "smartDecode(OptionalDefault), Bool → Int = \(name)",
                           expected: strategy == .legacy ? legacyDefault : enabledDefault) {
                    self.optional(try self.decoder(strategy).smartDecode(OptionalDefault.self, from: Data(payload.utf8)).value)
                }
            }
        }
    }

    private func collections(into report: inout BooleanIntegerReport) {
        let payload = #"{"ints":[true,false,2],"optionals":[true,false,null,5],"dict":{"a":true,"b":false,"c":3},"child":{"value":true}}"#
        for (name, strategy) in booleanModes {
            let checks: [(String, String, (Nested) -> String)] = strategy == .legacy ? [
                ("ints", "[73]", { self.ints($0.ints) }),
                ("optionals", "[73]", { self.optionalInts($0.optionals) }),
                ("dict", "{seed:73}", { self.dictionary($0.dict) }),
                ("child.value", "73", { String($0.child.value) }),
            ] : [
                ("ints", "[1,0,2]", { self.ints($0.ints) }),
                ("optionals", "[1,0,nil,5]", { self.optionalInts($0.optionals) }),
                ("dict", "{a:1,b:0,c:3}", { self.dictionary($0.dict) }),
                ("child.value", "1", { String($0.child.value) }),
            ]
            for (field, expected, read) in checks {
                report.add(input: payload, api: "smartDecode(Nested), Bool → Int = \(name), .\(field)", expected: expected) {
                    read(try self.decoder(strategy).smartDecode(Nested.self, from: Data(payload.utf8)))
                }
            }
        }
    }

    private func compactCollections(into report: inout BooleanIntegerReport) {
        let payload = #"{"ints":[true,false,2],"optionals":[true,false,null,5],"typed":{"a":true,"b":false,"c":3},"children":[{"value":true},{"value":false}],"dynamic":{"a":true,"b":false,"c":3}}"#
        let cases: [(SmartCodableOptions.CompactElementStrategy, String,
                     SmartJSONDecoder.BooleanToIntegerDecodingStrategy, String, String, String, String)] = [
            (.legacy, ".legacy", .legacy, ".legacy", "[1,0,2]", "{c:3}", "[73,73]"),
            (.legacy, ".legacy", .zeroOrOne, ".zeroOrOne", "[1,0,2]", "{a:1,b:0,c:3}", "[1,0]"),
            (.convert, ".convert", .legacy, ".legacy", "[2]", "{c:3}", "[73,73]"),
            (.convert, ".convert", .zeroOrOne, ".zeroOrOne", "[1,0,2]", "{a:1,b:0,c:3}", "[1,0]"),
        ]
        for (compact, compactName, boolean, booleanName, expectedInts, expectedTyped, expectedChildren) in cases {
            SmartCodableOptions.compactElementStrategy = compact
            let api = "smartDecode(Compact), Compact = \(compactName), Bool → Int = \(booleanName)"
            let checks: [(String, String, (Compact) -> String)] = [
                ("ints", expectedInts, { self.ints($0.ints) }),
                ("optionals", "[1,0,5]", { self.optionalInts($0.optionals) }),
                ("typed", expectedTyped, { self.dictionary($0.typed) }),
                ("children.value", expectedChildren, { self.ints($0.children.map(\.value)) }),
                ("dynamic.count", "3", { String($0.dynamic.count) }),
                ("dynamic.a", "CFBoolean(true)", { self.numberType($0.dynamic["a"]) }),
                ("dynamic.b", "CFBoolean(false)", { self.numberType($0.dynamic["b"]) }),
                ("dynamic.c", "CFNumber(3)", { self.numberType($0.dynamic["c"]) }),
            ]
            for (field, expected, read) in checks {
                report.add(input: payload, api: "\(api), .\(field)", expected: expected) {
                    read(try self.decoder(boolean).smartDecode(Compact.self, from: Data(payload.utf8)))
                }
            }
        }

        let bridging = #"{"a":true,"b":false}"#
        for (key, expectedType, expectedCast) in [("a", "CFBoolean(true)", "1"), ("b", "CFBoolean(false)", "0")] {
            report.add(input: bridging, api: "Foundation JSONSerialization, .\(key) 的 CF 类型", expected: expectedType) {
                let object = try JSONSerialization.jsonObject(with: Data(bridging.utf8)) as? [String: Any]
                return self.numberType(object?[key])
            }
            report.add(input: bridging, api: "Foundation JSONSerialization, .\(key) as? Int（旧桥接）", expected: expectedCast) {
                let object = try JSONSerialization.jsonObject(with: Data(bridging.utf8)) as? [String: Any]
                return self.optional(object?[key] as? Int)
            }
        }
    }

    private func otherValuesAndTransformers(into report: inout BooleanIntegerReport) {
        let cases: [(String, String)] = [
            (#"{}"#, "73"), (#"{"value":null}"#, "73"),
            (#"{"value":{}}"#, "73"), (#"{"value":[]}"#, "73"),
            (#"{"value":"true"}"#, "73"), (#"{"value":"false"}"#, "73"),
            (#"{"value":2}"#, "2"), (#"{"value":0}"#, "0"), (#"{"value":-3}"#, "-3"),
        ]
        for (payload, expected) in cases {
            for (name, strategy) in booleanModes {
                report.add(input: payload, api: "smartDecode(Value), Bool → Int = \(name)", expected: expected) {
                    String(try self.decoder(strategy).smartDecode(Value.self, from: Data(payload.utf8)).value)
                }
            }
        }
        for (token, enabledExpected) in [("true", "1"), ("false", "0")] {
            let payload = "{\"value\":\(token)}"
            for (name, strategy) in booleanModes {
                report.add(input: payload, api: "Transformer 返回 7 优先；Bool → Int = \(name)", expected: "7") {
                    String(try self.decoder(strategy).smartDecode(TransformerWins.self, from: Data(payload.utf8)).value)
                }
                report.add(input: payload, api: "Transformer 返回 nil 后回退；Bool → Int = \(name)",
                           expected: strategy == .legacy ? "73" : enabledExpected) {
                    String(try self.decoder(strategy).smartDecode(TransformerFallsThrough.self, from: Data(payload.utf8)).value)
                }
            }
        }
    }

    private func encodingAndIsolation(into report: inout BooleanIntegerReport) {
        for (token, expected) in [("true", "CFNumber(1)"), ("false", "CFNumber(0)")] {
            let payload = "{\"value\":\(token)}"
            report.add(input: payload, api: "smartDecode(.zeroOrOne) → SmartJSONEncoder.encode → JSON 类型", expected: expected) {
                let model = try self.decoder(.zeroOrOne).smartDecode(Value.self, from: Data(payload.utf8))
                let data = try SmartJSONEncoder().encode(model)
                let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                return self.numberType(object?["value"])
            }
            report.add(input: payload, api: "先 smartDecode(.zeroOrOne)，再独立 Value.deserialize（默认）", expected: "73") {
                _ = try self.decoder(.zeroOrOne).smartDecode(Value.self, from: Data(payload.utf8))
                return Value.deserialize(from: payload).map { String($0.value) } ?? "解码失败"
            }
        }
    }

    private func ints(_ values: [Int]) -> String {
        "[" + values.map(String.init).joined(separator: ",") + "]"
    }

    private func optionalInts(_ values: [Int?]) -> String {
        "[" + values.map(optional).joined(separator: ",") + "]"
    }

    private func optional(_ value: Int?) -> String {
        value.map(String.init) ?? "nil"
    }

    private func dictionary(_ values: [String: Int]) -> String {
        "{" + values.keys.sorted().map { "\($0):\(values[$0]!)" }.joined(separator: ",") + "}"
    }

    private func numberType(_ value: Any?) -> String {
        guard let number = value as? NSNumber else { return "非 NSNumber 或缺失" }
        if CFGetTypeID(number) == CFBooleanGetTypeID() {
            return "CFBoolean(\(number.boolValue ? "true" : "false"))"
        }
        if CFGetTypeID(number) == CFNumberGetTypeID() {
            return "CFNumber(\(number))"
        }
        return "未知 CF 类型"
    }
}

private struct BooleanIntegerReport {
    private var lines: [String] = []
    private var total = 0
    private var matched = 0

    mutating func add(input: String, api: String, expected: String, actual: () throws -> String) {
        total += 1
        let observed: String
        let matches: Bool
        do {
            observed = try actual()
            matches = observed == expected
        } catch {
            observed = "抛错：\(error)"
            matches = expected == "抛错"
        }
        if matches { matched += 1 }
        lines += ["输入: \(input)", "API: \(api)", "期望: \(expected)", "实际: \(observed)",
                  "判定: \(matches ? "一致" : "不一致")", ""]
    }

    func finish() -> [String] {
        let result = lines + ["合计: \(total) 项，一致 \(matched) 项，不一致 \(total - matched) 项"]
        for line in result { print("[BooleanIntegerDemo] \(line)") }
        return result
    }
}
