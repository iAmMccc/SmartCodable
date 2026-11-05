import XCTest
import Foundation
#if os(macOS)
import AppKit
#endif
#if canImport(Combine)
import Combine
#endif
@testable import SmartCodable

final class Branch702ReviewRegressionTests: XCTestCase {
    func testRawValueEnumCasesDecodeAcrossDistinctDeclaredDefaults() throws {
        // The finite domains match the Int and String examples. Invalid raw
        // values and other enum types are outside this test's scope.
        enum Sex: Int, SmartCaseDefaultable { case unknown = 0, man = 1, woman = 2 }
        enum Role: String, SmartCaseDefaultable { case admin, user, guest }
        struct FirstDefaults: SmartCodableX {
            var sex: Sex = .unknown
            var role: Role = .admin
        }
        struct LastDefaults: SmartCodableX {
            var sex: Sex = .woman
            var role: Role = .guest
        }

        let sexCases: [(Int, Sex)] = [(0, .unknown), (1, .man), (2, .woman)]
        let roleCases: [(String, Role)] = [("admin", .admin), ("user", .user), ("guest", .guest)]
        XCTAssertEqual(sexCases.count, Sex.allCases.count)
        XCTAssertEqual(roleCases.count, Role.allCases.count)
        for (input, expected) in sexCases {
            XCTAssertEqual(try XCTUnwrap(FirstDefaults.deserialize(from: ["sex": input])).sex, expected, "first default; input=\(input)")
            XCTAssertEqual(try XCTUnwrap(LastDefaults.deserialize(from: ["sex": input])).sex, expected, "last default; input=\(input)")
        }
        for (input, expected) in roleCases {
            XCTAssertEqual(try XCTUnwrap(FirstDefaults.deserialize(from: ["role": input])).role, expected, "first default; input=\(input)")
            XCTAssertEqual(try XCTUnwrap(LastDefaults.deserialize(from: ["role": input])).role, expected, "last default; input=\(input)")
        }

        let basicCases: [(Int, BasicModel.Sex)] = [(1, .man), (0, .women)]
        XCTAssertEqual(basicCases.count, BasicModel.Sex.allCases.count)
        for (input, expected) in basicCases {
            XCTAssertEqual(try XCTUnwrap(BasicModel.deserialize(from: ["sex": input])).sex, expected, "BasicModel input=\(input)")
        }

        // SmartFlatTests uses a file-private two-case enum; reproduce that
        // declaration and container shape without exposing the test fixture.
        enum FlatKind: Int, SmartCaseDefaultable { case fallback, preferred }
        struct FlatChild: SmartCodableX { var accid = "" }
        struct FlatFirstDefault: SmartCodableX {
            @SmartFlat var child: FlatChild?
            var kind: FlatKind = .fallback
        }
        struct FlatLastDefault: SmartCodableX {
            @SmartFlat var child: FlatChild?
            var kind: FlatKind = .preferred
        }
        let flatCases: [(Int, FlatKind)] = [(0, .fallback), (1, .preferred)]
        XCTAssertEqual(flatCases.count, FlatKind.allCases.count)
        for (input, expected) in flatCases {
            let payload: [String: Any] = ["kind": input, "accid": "a1"]
            let first = try XCTUnwrap(FlatFirstDefault.deserialize(from: payload))
            let last = try XCTUnwrap(FlatLastDefault.deserialize(from: payload))
            XCTAssertEqual(first.child?.accid, "a1")
            XCTAssertEqual(last.child?.accid, "a1")
            XCTAssertEqual(first.kind, expected, "flat first default; input=\(input)")
            XCTAssertEqual(last.kind, expected, "flat last default; input=\(input)")
        }
    }

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

    func testR2CompactModels() throws {
        struct Child: SmartCodableX { var id: Int = -1 }
        struct Host: SmartCodableX { @SmartCompact.Array var children: [Child] = [] }
        let input: [String: Any] = ["children": [["id": 1], NSNull(), ["id": 2]] as [Any]]
        let model = try XCTUnwrap(Host.deserialize(from: input))
        XCTAssertEqual(model.children.map(\.id), [1, 2])
    }

    func testR3UpdaterPreservesOtherField() {
        struct Model: SmartCodableX {
            var firstName = "old-first"
            var name = "old-full"
            static func mappingForKey() -> [SmartKeyTransformer]? {
                [CodingKeys.firstName <--- ["first_name", "name"]]
            }
        }
        var model = Model()
        SmartUpdater.update(&model, from: ["first_name": "Ada", "name": "Ada Lovelace"])
        XCTAssertEqual(model.firstName, "Ada")
        XCTAssertEqual(model.name, "Ada Lovelace")
    }

    func testR1FloatingContainers() throws {
        let previous = SmartCodableOptions.compactElementStrategy
        defer { SmartCodableOptions.compactElementStrategy = previous }
        SmartCodableOptions.compactElementStrategy = .convert

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

        var plainTokens = 0
        for token in ["nan", "inf", "-inf"] {
            XCTAssertEqual(Model.deserialize(from: ["value": token])?.value, -1, token)
            plainTokens += 1
        }
        XCTAssertEqual(plainTokens, 3)
    }

    func testR2CallbacksAndOrdinaryArray() throws {
        struct Child: SmartCodableX {
            var id = -1
            var calls = 0
            mutating func didFinishMapping() { calls += 1; id += 10 }
        }
        struct DecodeOnly: SmartDecodable {
            var id = -1
            var calls = 0
            mutating func didFinishMapping() { calls += 1; id += 10 }
        }
        struct Host: SmartCodableX {
            @SmartCompact.Array var compact: [Child] = []
            @SmartCompact.Array var only: [DecodeOnly] = []
            var ordinary: [Child] = []
        }
        let elements: [Any] = [["id": 1], NSNull(), "bad", ["id": 2]]
        let ordinary: [Any] = [["id": 1], [String: Int](), ["id": 2]]
        let host = try XCTUnwrap(Host.deserialize(from: ["compact": elements, "only": elements, "ordinary": ordinary]))
        XCTAssertEqual(host.compact.map(\.id), [11, 12])
        XCTAssertEqual(host.compact.map(\.calls), [1, 1])
        // `DecodeOnly` is a plain `SmartDecodable`, so its elements belong to the
        // opt-in conversion domain: the 7.0.1 JSON-value bridge cannot build them.
        XCTAssertEqual(host.only.map(\.id), [])
        let previousElements = SmartCodableOptions.compactElementStrategy
        defer { SmartCodableOptions.compactElementStrategy = previousElements }
        SmartCodableOptions.compactElementStrategy = .convert
        let converted = try XCTUnwrap(Host.deserialize(from: ["compact": elements, "only": elements, "ordinary": ordinary]))
        XCTAssertEqual(converted.only.map(\.id), [11, 12])
        XCTAssertEqual(converted.only.map(\.calls), [1, 1])
        XCTAssertEqual(host.ordinary.map(\.id), [11, 9, 12])
        XCTAssertEqual(host.ordinary.map(\.calls), [1, 1, 1])

        // Non-optional model arrays fall back to the declared default when an element is null or not an object (ARR-01).
        let withNull = try XCTUnwrap(Host.deserialize(from: ["ordinary": [["id": 1], NSNull(), ["id": 2]] as [Any]]))
        XCTAssertEqual(withNull.ordinary.map(\.id), [])
        let withBad = try XCTUnwrap(Host.deserialize(from: ["ordinary": [["id": 1], "bad", ["id": 2]] as [Any]]))
        XCTAssertEqual(withBad.ordinary.map(\.id), [])
    }

    func testCompactOptionalModelsKeepLegacyEmptyResultWithoutCallbacks() throws {
        struct Host: SmartDecodable {
            @SmartCompact.Array var values: [Branch702CallbackChild?] = []
        }
        let inputs: [[Any]] = [
            [["id": 1], ["id": 2]],
            [["id": 1], NSNull(), ["id": 2]],
            [["id": 1], "bad", ["id": 2]],
            []
        ]
        for strategy in [SmartJSONDecoder.UnkeyedDecodingStrategy.legacy, .consumeOnce] {
            for input in inputs {
                let trace = Branch702CallbackTrace()
                let decoder = SmartJSONDecoder()
                decoder.smartUnkeyedDecodingStrategy = strategy
                decoder.userInfo[Branch702CallbackTrace.key] = trace
                let host = try decoder.smartDecode(Host.self, from: ["values": input])
                // 7.0.1 does not decode Optional model elements in Compact arrays.
                XCTAssertEqual(host.values.map { $0?.id }, [])
                XCTAssertEqual(host.values.map { $0?.calls }, [])
                XCTAssertEqual(trace.callbacks, [])
            }
        }
    }

    func testR3AllUpdateInputs() {
        struct Model: SmartCodableX {
            var firstName = "old-first"
            var name = "old-full"
            static func mappingForKey() -> [SmartKeyTransformer]? {
                [CodingKeys.firstName <--- ["first_name", "name"]]
            }
        }
        let json = "{\"first_name\":\"Ada\",\"name\":\"Ada Lovelace\"}"
        var stringModel = Model()
        var dataModel = Model()
        SmartUpdater.update(&stringModel, from: json)
        SmartUpdater.update(&dataModel, from: Data(json.utf8))
        XCTAssertEqual(stringModel.firstName, "Ada")
        XCTAssertEqual(stringModel.name, "Ada Lovelace")
        XCTAssertEqual(dataModel.firstName, "Ada")
        XCTAssertEqual(dataModel.name, "Ada Lovelace")
    }

    func testR4RenamedColorDeclaration() throws {
        struct Model: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rrggbb(.hash)) var colorValue: ColorObject?
            enum CodingKeys: String, CodingKey { case colorValue = "color_value" }
            static let defaultValueKeyMapping = ["color_value": "colorValue"]
        }
        let model = try XCTUnwrap(Model.deserialize(from: ["color_value": "FF0000"]))
        let result = try XCTUnwrap(model.toDictionary())
        let encoded = try XCTUnwrap(result["color_value"] as? String)
        XCTAssertEqual(encoded, "#FF0000")
    }

    func testR4RenamedDateDeclaration() throws {
        struct Model: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartDate(wrappedValue: nil, encodeFormat: .timestampMilliseconds) var createdAt: Date?
            enum CodingKeys: String, CodingKey { case createdAt = "created_at" }
            static let defaultValueKeyMapping = ["created_at": "createdAt"]
        }
        let model = try XCTUnwrap(Model.deserialize(from: ["created_at": 1_700_000_000]))
        let result = try XCTUnwrap(model.toDictionary())
        XCTAssertEqual((result["created_at"] as? NSNumber)?.int64Value, 1_700_000_000_000)
    }

    func testR5NestedArrayElements() {
        struct Model: SmartCodableX { var m: [[Int]] = [[9]] }
        // 7.0.1 语义：嵌套数组的元素解码失败时错误向上传播，整个属性回退声明默认值 [[9]]。
        let samples: [([String: Any], [[Int]])] = [
            (["m": [[1, 2], "x", [3]] as [Any]], [[9]]),
            (["m": [[1, "a"] as [Any], [3]] as [Any]], [[9]]),
            (["m": "x"], [[9]]),
            (["m": [[1, 2], NSNull(), [3]] as [Any]], [[9]])
        ]
        var executed = 0
        for (payload, expected) in samples {
            XCTAssertEqual(Model.deserialize(from: payload)?.m, expected)
            executed += 1
        }
        XCTAssertEqual(executed, 4)
    }

    func testR6OptionalFieldLogMatrix() {
        defer {
            SmartSentinel.debugMode = .none
            SmartSentinel.onLogGenerated { _ in }
        }
        struct RequiredModel: SmartCodableX { var value: Int = 0 }
        struct OptionalModel: SmartCodableX { var value: Int? }
        // Optional 缺键与 null 解码为 nil，不是解析错误，期望 0 条。
        // 非可选缺键与 null 只在 verbose 记 1 条；alert 不包含该级别，仍为 0。
        let cells: [(name: String, mode: SmartSentinel.Level, optional: Bool, payload: [String: Any], expected: Int)] = [
            ("none/req/缺失", .none, false, [:], 0),
            ("none/req/null", .none, false, ["value": NSNull()], 0),
            ("none/req/类型不符", .none, false, ["value": "abc"], 0),
            ("none/req/有效", .none, false, ["value": 1], 0),
            ("none/opt/缺失", .none, true, [:], 0),
            ("none/opt/null", .none, true, ["value": NSNull()], 0),
            ("none/opt/类型不符", .none, true, ["value": "abc"], 0),
            ("none/opt/有效", .none, true, ["value": 1], 0),
            ("verbose/req/缺失", .verbose, false, [:], 1),
            ("verbose/req/null", .verbose, false, ["value": NSNull()], 1),
            ("verbose/req/类型不符", .verbose, false, ["value": "abc"], 1),
            ("verbose/req/有效", .verbose, false, ["value": 1], 0),
            ("verbose/opt/缺失", .verbose, true, [:], 0),
            ("verbose/opt/null", .verbose, true, ["value": NSNull()], 0),
            ("verbose/opt/类型不符", .verbose, true, ["value": "abc"], 1),
            ("verbose/opt/有效", .verbose, true, ["value": 1], 0),
            ("alert/req/缺失", .alert, false, [:], 0),
            ("alert/req/null", .alert, false, ["value": NSNull()], 0),
            ("alert/req/类型不符", .alert, false, ["value": "abc"], 1),
            ("alert/req/有效", .alert, false, ["value": 1], 0),
            ("alert/opt/缺失", .alert, true, [:], 0),
            ("alert/opt/null", .alert, true, ["value": NSNull()], 0),
            ("alert/opt/类型不符", .alert, true, ["value": "abc"], 1),
            ("alert/opt/有效", .alert, true, ["value": 1], 0)
        ]
        var executed = 0
        for cell in cells {
            SmartSentinel.debugMode = cell.mode
            var messages = 0
            SmartSentinel.onLogGenerated { _ in messages += 1 }
            if cell.optional {
                _ = OptionalModel.deserialize(from: cell.payload)
            } else {
                _ = RequiredModel.deserialize(from: cell.payload)
            }
            let flushed = expectation(description: cell.name)
            DispatchQueue.main.async { flushed.fulfill() }
            wait(for: [flushed], timeout: 1)
            XCTAssertEqual(messages, cell.expected, cell.name)
            executed += 1
        }
        XCTAssertEqual(executed, 24)
    }

    func testR7NonFiniteFloatMatrix() throws {
        struct FloatModel: SmartCodableX { var value: Float = -1 }
        struct DoubleModel: SmartCodableX { var value: Double = -1 }
        struct CGModel: SmartCodableX { var value: CGFloat = -1 }
        let tokens = ["3.5", "1e39", "1e400", "nan", "inf", "-inf", "+INF", "-INF", "NaN"]
        let configured: Set<SmartDecodingOption> = [.float(.convertFromString(positiveInfinity: "+INF", negativeInfinity: "-INF", nan: "NaN"))]
        enum Kind {
            case fallback
            case finite(Double)
            case positiveInfinity
            case negativeInfinity
            case nan
        }
        func kind(typeName: String, token: String, configured: Bool) -> Kind {
            if token == "3.5" { return .finite(3.5) }
            if token == "1e39" { return typeName == "Float" ? .fallback : .finite(1e39) }
            if token == "1e400" || token == "nan" || token == "inf" || token == "-inf" { return .fallback }
            guard configured else { return .fallback }
            switch token {
            case "+INF": return .positiveInfinity
            case "-INF": return .negativeInfinity
            case "NaN": return .nan
            default: return .fallback
            }
        }
        func assertValue<T: BinaryFloatingPoint>(_ actual: T, _ expected: Kind, _ label: String) {
            switch expected {
            case .fallback:
                XCTAssertEqual(actual, T(-1), label)
            case .finite(let number):
                XCTAssertEqual(actual, T(number), label)
            case .positiveInfinity:
                XCTAssertEqual(actual, T.infinity, label)
            case .negativeInfinity:
                XCTAssertEqual(actual, -T.infinity, label)
            case .nan:
                XCTAssertTrue(actual.isNaN, label)
            }
        }
        var executed = 0
        for useOptions in [false, true] {
            let options: Set<SmartDecodingOption>? = useOptions ? configured : nil
            for token in tokens {
                let payload = ["value": token]
                let label = "\(useOptions ? "convert" : "plain")/\(token)"
                assertValue(try XCTUnwrap(FloatModel.deserialize(from: payload, options: options)).value, kind(typeName: "Float", token: token, configured: useOptions), "Float/" + label)
                assertValue(try XCTUnwrap(DoubleModel.deserialize(from: payload, options: options)).value, kind(typeName: "Double", token: token, configured: useOptions), "Double/" + label)
                assertValue(try XCTUnwrap(CGModel.deserialize(from: payload, options: options)).value, kind(typeName: "CGFloat", token: token, configured: useOptions), "CGFloat/" + label)
                executed += 3
            }
        }
        XCTAssertEqual(executed, 54)
    }

    func testR8CompactArrayElementTypes() {
        let previous = SmartCodableOptions.numberStrategy
        defer { SmartCodableOptions.numberStrategy = previous }
        let previousElements = SmartCodableOptions.compactElementStrategy
        defer { SmartCodableOptions.compactElementStrategy = previousElements }
        SmartCodableOptions.compactElementStrategy = .convert
        func compact<T: Codable & Equatable>(_: T.Type, _ values: [Any]) -> [T]? {
            Branch702CompactHost<T>.deserialize(from: ["values": values])?.values
        }
        var executed = 0
        XCTAssertEqual(compact(Int.self, [7, "x"]), [7]); executed += 1
        XCTAssertEqual(compact(Int8.self, [Int8.min, 128]), [Int8.min]); executed += 1
        XCTAssertEqual(compact(Int16.self, [Int16.min, 32768]), [Int16.min]); executed += 1
        XCTAssertEqual(compact(Int32.self, [Int32.min, 2147483648]), [Int32.min]); executed += 1
        XCTAssertEqual(compact(Int64.self, [Int64.min, "9223372036854775808"]), [Int64.min]); executed += 1
        XCTAssertEqual(compact(UInt.self, [1, -1]), [1]); executed += 1
        XCTAssertEqual(compact(UInt8.self, [255, -1]), [255]); executed += 1
        XCTAssertEqual(compact(UInt16.self, [65535, 65536]), [65535]); executed += 1
        XCTAssertEqual(compact(UInt32.self, [4294967295, 4294967296]), [4294967295]); executed += 1
        XCTAssertEqual(compact(UInt64.self, ["18446744073709551615", -1]), [18446744073709551615 as UInt64]); executed += 1
        XCTAssertEqual(compact(Float.self, ["1.5", "x"]), [1.5]); executed += 1
        XCTAssertEqual(compact(Double.self, ["2.5", "x"]), [2.5]); executed += 1
        XCTAssertEqual(compact(CGFloat.self, ["1.25", "x"]), [1.25]); executed += 1
        XCTAssertEqual(compact(Bool.self, ["yes", "maybe"]), [true]); executed += 1
        XCTAssertEqual(compact(String.self, ["a", NSNull()]), ["a"]); executed += 1

        let boolForms: [(Any, Bool)] = [
            (true, true), (false, false), (1, true), (0, false),
            ("1", true), ("YES", true), ("Yes", true), ("yes", true),
            ("TRUE", true), ("True", true), ("true", true),
            ("0", false), ("NO", false), ("No", false), ("no", false),
            ("FALSE", false), ("False", false), ("false", false)
        ]
        for (input, expected) in boolForms {
            XCTAssertEqual(compact(Bool.self, [input]), [expected], "\(input)")
            executed += 1
        }

        let mixed: [Any] = [1, "2", "x", NSNull(), 3.5, 4]
        SmartCodableOptions.numberStrategy = .strict
        XCTAssertEqual(compact(Int.self, mixed), [1, 2, 4]); executed += 1
        SmartCodableOptions.numberStrategy = .truncate
        XCTAssertEqual(compact(Int.self, mixed), [1, 2, 3, 4]); executed += 1
        SmartCodableOptions.numberStrategy = .rounded
        XCTAssertEqual(compact(Int.self, mixed), [1, 2, 4, 4]); executed += 1

        // Default `.legacy` keeps the 7.0.1 acceptance domain: only values the JSON
        // bridge already holds survive the cast, and Bool elements still cast to Int.
        SmartCodableOptions.compactElementStrategy = .legacy
        XCTAssertEqual(compact(Int.self, [1, "2", true]), [1, 1]); executed += 1
        XCTAssertEqual(compact(Bool.self, ["YES", true]), [true]); executed += 1
        XCTAssertEqual(compact(String.self, [1, "a"]), ["a"]); executed += 1
        XCTAssertEqual(compact(Double.self, [2.5, "2.5"]), [2.5]); executed += 1
        XCTAssertEqual(executed, 40)
    }

    func testR9TopLevelScalarEncoding() throws {
        func text<T: Encodable>(_ value: T) throws -> String {
            let encoder = SmartJSONEncoder()
            return try XCTUnwrap(String(data: try encoder.encode(value), encoding: .utf8))
        }
        var executed = 0
        XCTAssertEqual(try text(true), "true"); executed += 1
        XCTAssertEqual(try text("hi"), "\"hi\""); executed += 1
        XCTAssertEqual(try text(Int(-1)), "-1"); executed += 1
        XCTAssertEqual(try text(Int8(-128)), "-128"); executed += 1
        XCTAssertEqual(try text(Int16(-32768)), "-32768"); executed += 1
        XCTAssertEqual(try text(Int32.min), "-2147483648"); executed += 1
        XCTAssertEqual(try text(Int64.min), "-9223372036854775808"); executed += 1
        XCTAssertEqual(try text(UInt(1)), "1"); executed += 1
        XCTAssertEqual(try text(UInt8(255)), "255"); executed += 1
        XCTAssertEqual(try text(UInt16(65535)), "65535"); executed += 1
        XCTAssertEqual(try text(UInt32.max), "4294967295"); executed += 1
        XCTAssertEqual(try text(UInt64.max), "18446744073709551615"); executed += 1
        XCTAssertEqual(try text(Float(1.5)), "1.5"); executed += 1
        XCTAssertEqual(try text(Double(1.5)), "1.5"); executed += 1
        XCTAssertEqual(executed, 14)
    }

    func testR10SmartDateThresholdAndFormats() throws {
        struct Threshold: SmartCodableX {
            @SmartDate var date: Date?
        }
        let below = try XCTUnwrap(Threshold.deserialize(from: ["date": 999_999_999_999])?.date)
        XCTAssertEqual(below.timeIntervalSince1970, 999_999_999_999)
        let boundary = try XCTUnwrap(Threshold.deserialize(from: ["date": 1_000_000_000_000])?.date)
        // 7.0.1 语义：毫秒阈值为 double > 1_000_000_000_000，恰好 1e12 仍按秒解析。
        XCTAssertEqual(boundary.timeIntervalSince1970, 1_000_000_000_000)
        let above = try XCTUnwrap(Threshold.deserialize(from: ["date": 1_000_000_000_001])?.date)
        XCTAssertEqual(above.timeIntervalSince1970, 1_000_000_000.001, accuracy: 1e-6)

        func created<M: SmartCodableX>(_: M.Type) throws -> Any {
            let model = try XCTUnwrap(M.deserialize(from: ["created_at": 1_700_000_000]))
            return try XCTUnwrap(model.toDictionary()?["created_at"])
        }
        struct TimestampModel: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartDate(wrappedValue: nil, encodeFormat: .timestamp) var createdAt: Date?
            enum CodingKeys: String, CodingKey { case createdAt = "created_at" }
            static let defaultValueKeyMapping = ["created_at": "createdAt"]
        }
        struct MillisecondModel: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartDate(wrappedValue: nil, encodeFormat: .timestampMilliseconds) var createdAt: Date?
            enum CodingKeys: String, CodingKey { case createdAt = "created_at" }
            static let defaultValueKeyMapping = ["created_at": "createdAt"]
        }
        struct ISOModel: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartDate(wrappedValue: nil, encodeFormat: .iso8601) var createdAt: Date?
            enum CodingKeys: String, CodingKey { case createdAt = "created_at" }
            static let defaultValueKeyMapping = ["created_at": "createdAt"]
        }
        struct FormattedModel: SmartCodableX, SmartDefaultValueKeyMapping {
            static let dayFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }()
            @SmartDate(wrappedValue: nil, encodeFormat: .formatted(FormattedModel.dayFormatter)) var createdAt: Date?
            enum CodingKeys: String, CodingKey { case createdAt = "created_at" }
            static let defaultValueKeyMapping = ["created_at": "createdAt"]
        }
        XCTAssertEqual((try created(TimestampModel.self) as? NSNumber)?.int64Value, 1_700_000_000)
        XCTAssertEqual((try created(MillisecondModel.self) as? NSNumber)?.int64Value, 1_700_000_000_000)
        XCTAssertEqual(try created(ISOModel.self) as? String, "2023-11-14T22:13:20Z")
        XCTAssertEqual(try created(FormattedModel.self) as? String, "2023-11-14")
    }

    func testR11HexColorFormatsRestoredForRenamedKey() throws {
        func encoded<M: SmartCodableX>(_: M.Type) throws -> String {
            let model = try XCTUnwrap(M.deserialize(from: ["color_value": "FF0000"]))
            let dictionary = try XCTUnwrap(model.toDictionary())
            return try XCTUnwrap(dictionary["color_value"] as? String)
        }
        struct RGBHash: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rgb(.hash)) var colorValue: ColorObject?
            enum CodingKeys: String, CodingKey { case colorValue = "color_value" }
            static let defaultValueKeyMapping = ["color_value": "colorValue"]
        }
        struct RGBZeroX: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rgb(.zeroX)) var colorValue: ColorObject?
            enum CodingKeys: String, CodingKey { case colorValue = "color_value" }
            static let defaultValueKeyMapping = ["color_value": "colorValue"]
        }
        struct RGBNone: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rgb(.none)) var colorValue: ColorObject?
            enum CodingKeys: String, CodingKey { case colorValue = "color_value" }
            static let defaultValueKeyMapping = ["color_value": "colorValue"]
        }
        struct RRGGBBHash: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rrggbb(.hash)) var colorValue: ColorObject?
            enum CodingKeys: String, CodingKey { case colorValue = "color_value" }
            static let defaultValueKeyMapping = ["color_value": "colorValue"]
        }
        struct RRGGBBZeroX: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rrggbb(.zeroX)) var colorValue: ColorObject?
            enum CodingKeys: String, CodingKey { case colorValue = "color_value" }
            static let defaultValueKeyMapping = ["color_value": "colorValue"]
        }
        struct RRGGBBNone: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rrggbb(.none)) var colorValue: ColorObject?
            enum CodingKeys: String, CodingKey { case colorValue = "color_value" }
            static let defaultValueKeyMapping = ["color_value": "colorValue"]
        }
        struct RGBAHash: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rgba(.hash)) var colorValue: ColorObject?
            enum CodingKeys: String, CodingKey { case colorValue = "color_value" }
            static let defaultValueKeyMapping = ["color_value": "colorValue"]
        }
        struct RGBAZeroX: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rgba(.zeroX)) var colorValue: ColorObject?
            enum CodingKeys: String, CodingKey { case colorValue = "color_value" }
            static let defaultValueKeyMapping = ["color_value": "colorValue"]
        }
        struct RGBANone: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rgba(.none)) var colorValue: ColorObject?
            enum CodingKeys: String, CodingKey { case colorValue = "color_value" }
            static let defaultValueKeyMapping = ["color_value": "colorValue"]
        }
        struct RRGGBBAAHash: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rrggbbaa(.hash)) var colorValue: ColorObject?
            enum CodingKeys: String, CodingKey { case colorValue = "color_value" }
            static let defaultValueKeyMapping = ["color_value": "colorValue"]
        }
        struct RRGGBBAAZeroX: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rrggbbaa(.zeroX)) var colorValue: ColorObject?
            enum CodingKeys: String, CodingKey { case colorValue = "color_value" }
            static let defaultValueKeyMapping = ["color_value": "colorValue"]
        }
        struct RRGGBBAANone: SmartCodableX, SmartDefaultValueKeyMapping {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rrggbbaa(.none)) var colorValue: ColorObject?
            enum CodingKeys: String, CodingKey { case colorValue = "color_value" }
            static let defaultValueKeyMapping = ["color_value": "colorValue"]
        }
        var executed = 0
        XCTAssertEqual(try encoded(RGBHash.self), "#F00"); executed += 1
        XCTAssertEqual(try encoded(RGBZeroX.self), "0xF00"); executed += 1
        XCTAssertEqual(try encoded(RGBNone.self), "F00"); executed += 1
        XCTAssertEqual(try encoded(RRGGBBHash.self), "#FF0000"); executed += 1
        XCTAssertEqual(try encoded(RRGGBBZeroX.self), "0xFF0000"); executed += 1
        XCTAssertEqual(try encoded(RRGGBBNone.self), "FF0000"); executed += 1
        XCTAssertEqual(try encoded(RGBAHash.self), "#F00F"); executed += 1
        XCTAssertEqual(try encoded(RGBAZeroX.self), "0xF00F"); executed += 1
        XCTAssertEqual(try encoded(RGBANone.self), "F00F"); executed += 1
        XCTAssertEqual(try encoded(RRGGBBAAHash.self), "#FF0000FF"); executed += 1
        XCTAssertEqual(try encoded(RRGGBBAAZeroX.self), "0xFF0000FF"); executed += 1
        XCTAssertEqual(try encoded(RRGGBBAANone.self), "FF0000FF"); executed += 1
        XCTAssertEqual(executed, 12)
    }

    func testR18HexColorChannelRoundTrip() throws {
        struct LongModel: SmartCodableX {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rrggbbaa(.none)) var color: ColorObject?
        }
        struct ShortModel: SmartCodableX {
            @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rgba(.none)) var color: ColorObject?
        }
        func roundTrip<M: SmartCodableX>(_ type: M.Type, _ input: String) throws -> String {
            let model = try XCTUnwrap(type.deserialize(from: ["color": input]))
            let dictionary = try XCTUnwrap(model.toDictionary())
            return try XCTUnwrap(dictionary["color"] as? String)
        }

        var longCases = 0
        for channel in 0..<4 {
            for value in 0...255 {
                var channels = [0x80, 0x80, 0x80, 0x80]
                channels[channel] = value
                let input = String(format: "%02X%02X%02X%02X", channels[0], channels[1], channels[2], channels[3])
                XCTAssertEqual(try roundTrip(LongModel.self, input), input, input)
                longCases += 1
            }
        }
        XCTAssertEqual(longCases, 1024)

        var shortCases = 0
        for channel in 0..<4 {
            for value in 0...15 {
                var channels = [8, 8, 8, 8]
                channels[channel] = value
                let input = String(format: "%01X%01X%01X%01X", channels[0], channels[1], channels[2], channels[3])
                XCTAssertEqual(try roundTrip(ShortModel.self, input), input, input)
                shortCases += 1
            }
        }
        XCTAssertEqual(shortCases, 64)
    }

    // NSColor 只在 macOS 上可用。
    #if os(macOS)
    func testR19HexColorEncodesCodeCreatedColors() throws {
        struct SRGBRed: SmartCodableX {
            @SmartHexColor(wrappedValue: NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1), encodeHexFormat: .rrggbb(.hash)) var c: ColorObject?
        }
        struct DeviceRed: SmartCodableX {
            @SmartHexColor(wrappedValue: NSColor(deviceRed: 1, green: 0, blue: 0, alpha: 1), encodeHexFormat: .rrggbb(.hash)) var c: ColorObject?
        }
        struct CalibratedRed: SmartCodableX {
            @SmartHexColor(wrappedValue: NSColor(calibratedRed: 1, green: 0, blue: 0, alpha: 1), encodeHexFormat: .rrggbb(.hash)) var c: ColorObject?
        }
        struct SRGBSample: SmartCodableX {
            @SmartHexColor(
                wrappedValue: NSColor(srgbRed: 0x12 / 255, green: 0xAB / 255, blue: 0x34 / 255, alpha: 1),
                encodeHexFormat: .rrggbb(.hash)
            ) var c: ColorObject?
        }
        func encoded<M: SmartCodableX>(_ model: M) throws -> String {
            let dictionary = try XCTUnwrap(model.toDictionary())
            return try XCTUnwrap(dictionary["c"] as? String)
        }
        var executed = 0
        XCTAssertEqual(try encoded(SRGBRed()), "#FF0000"); executed += 1
        XCTAssertEqual(try encoded(DeviceRed()), "#FF0000"); executed += 1
        XCTAssertEqual(try encoded(CalibratedRed()), "#FF0000"); executed += 1
        XCTAssertEqual(try encoded(SRGBSample()), "#12AB34"); executed += 1
        XCTAssertEqual(executed, 4)
    }
    #endif

    func testR20URLTransformerEncodesRawInput() {
        let transformer = SmartURLTransformer()
        let samples = [
            ("https://a.com/a b", "https://a.com/a%20b"),
            ("https://a.com/中文", "https://a.com/%E4%B8%AD%E6%96%87"),
            ("https://a.com/%E4%B8%AD", "https://a.com/%E4%B8%AD")
        ]
        var executed = 0
        for (input, expected) in samples {
            XCTAssertEqual(transformer.transformFromJSON(input)?.absoluteString, expected, input)
            executed += 1
        }
        XCTAssertEqual(executed, 3)
    }

    #if canImport(Combine)
    func testR12SmartPublishedInObservableObject() {
        final class Host: ObservableObject {
            @SmartPublished var score = 7
        }
        let host = Host()
        var fired = 0
        let token = host.objectWillChange.sink { fired += 1 }
        host.score = 9
        XCTAssertEqual(host.score, 9)
        XCTAssertEqual(fired, 1)
        withExtendedLifetime(token) {}
    }
    #endif

    func testR13UpdaterNilAndEmptyPreserving() {
        struct Model: SmartCodableX {
            var name = "declared"
            var count = 1
        }
        final class Counter { var value = 0 }
        let counter = Counter()
        let preserving: (inout Model, Model) -> Void = { _, _ in counter.value += 1 }
        func seeded() -> Model {
            var model = Model()
            model.name = "kept"
            model.count = 4
            return model
        }
        func assertUnchanged(_ model: Model, calls: Int, file: StaticString = #filePath, line: UInt = #line) {
            XCTAssertEqual(model.name, "kept", file: file, line: line)
            XCTAssertEqual(model.count, 4, file: file, line: line)
            XCTAssertEqual(counter.value, calls, file: file, line: line)
        }
        var executed = 0
        var model = seeded()
        counter.value = 0
        SmartUpdater.update(&model, from: nil as [String: Any]?, preserving: preserving)
        assertUnchanged(model, calls: 0)
        executed += 1
        model = seeded()
        counter.value = 0
        SmartUpdater.update(&model, from: nil as Data?, preserving: preserving)
        assertUnchanged(model, calls: 0)
        executed += 1
        model = seeded()
        counter.value = 0
        SmartUpdater.update(&model, from: nil as String?, preserving: preserving)
        assertUnchanged(model, calls: 0)
        executed += 1
        model = seeded()
        counter.value = 0
        SmartUpdater.update(&model, from: [String: Any](), preserving: preserving)
        assertUnchanged(model, calls: 1)
        executed += 1
        XCTAssertEqual(executed, 4)
    }

    func testR14DictionaryJSONStringExclusions() {
        struct DictModel: SmartCodableX { var d: [String: Int] = ["z": 0] }
        struct NestedModel: SmartCodableX { var n: [String: [String: Int]] = [:] }
        var executed = 0
        XCTAssertEqual(DictModel.deserialize(from: ["d": "[1]"])?.d, ["z": 0]); executed += 1
        XCTAssertEqual(DictModel.deserialize(from: ["d": "abc"])?.d, ["z": 0]); executed += 1
        XCTAssertEqual(NestedModel.deserialize(from: ["n": "{\"a\":{\"x\":1}}"])?.n, ["a": ["x": 1]]); executed += 1
        XCTAssertEqual(executed, 3)
    }

    func testR15CrossLevelNullAlias() {
        struct Model: SmartCodableX {
            var name = "dft"
            static func mappingForKey() -> [SmartKeyTransformer]? {
                [CodingKeys.name <--- ["a.b", "alt"]]
            }
        }
        var executed = 0
        XCTAssertEqual(Model.deserialize(from: ["a": ["b": NSNull()], "alt": "X"])?.name, "X"); executed += 1
        XCTAssertEqual(Model.deserialize(from: ["a": ["b": "Y"], "alt": "X"])?.name, "Y"); executed += 1
        XCTAssertEqual(Model.deserialize(from: ["a": ["b": NSNull()], "alt": NSNull()])?.name, "dft"); executed += 1
        XCTAssertEqual(Model.deserialize(from: ["a": ["b": ""], "alt": "X"])?.name, ""); executed += 1
        XCTAssertEqual(executed, 4)
    }

    func testR16SmartAnyNumbers() throws {
        struct Model: SmartCodableX {
            @SmartAny var v: Any? = nil
        }
        let scientific = try XCTUnwrap(Model.deserialize(from: "{\"v\":1e5}"))
        let scientificNumber = try XCTUnwrap(scientific.v as? NSNumber)
        XCTAssertEqual(scientificNumber.doubleValue, 100000)
        let wide = try XCTUnwrap(Model.deserialize(from: "{\"v\":18446744073709551615}"))
        let wideNumber = try XCTUnwrap(wide.v as? NSNumber)
        XCTAssertEqual(wideNumber.stringValue, "18446744073709551615")
    }

    func testOptionalModelArrayFailureDoesNotRunCompletionBeforeFallback() throws {
        struct Host: SmartDecodable {
            var optional: [Branch702CallbackChild?] = []
            var ordinary: [Branch702CallbackChild] = []
        }
        let elements: [Any] = [["id": 1], "bad", ["id": 2]]
        for strategy in [SmartJSONDecoder.UnkeyedDecodingStrategy.legacy, .consumeOnce] {
            let trace = Branch702CallbackTrace()
            let decoder = SmartJSONDecoder()
            decoder.smartUnkeyedDecodingStrategy = strategy
            decoder.userInfo[Branch702CallbackTrace.key] = trace

            let optional = try decoder.smartDecode(Host.self, from: ["optional": elements])
            XCTAssertEqual(optional.optional.count, 0)
            XCTAssertEqual(trace.callbacks, [])
            XCTAssertEqual(trace.events, ["decoded:1"])

            trace.callbacks = []
            trace.events = []
            let ordinary = try decoder.smartDecode(Host.self, from: ["ordinary": elements])
            XCTAssertEqual(ordinary.ordinary.count, 0)
            // The first model completes before the next element fails. Falling
            // back to [] must not erase that externally visible side effect.
            XCTAssertEqual(trace.callbacks, [1])
            XCTAssertEqual(trace.events, ["decoded:1", "callback:1"])
        }
    }

    func testR17OptionalModelArrayKeepsElementPositions() throws {
        struct Child: SmartCodableX {
            var id = -1
            var calls = 0
            mutating func didFinishMapping() { calls += 1; id += 10 }
        }
        struct Host: SmartCodableX {
            var optional: [Child?] = []
        }
        let withNull = try XCTUnwrap(Host.deserialize(from: ["optional": [["id": 1], NSNull(), ["id": 2]] as [Any]]))
        XCTAssertEqual(withNull.optional.count, 3)
        // 7.0.1 语义：`[Child?]` 的元素类型是 Optional，不算 SmartDecodable，
        // 默认不触发完成回调。
        XCTAssertEqual(withNull.optional.map { $0?.id }, [1, nil, 2])
        XCTAssertEqual(withNull.optional.map { $0?.calls }, [0, nil, 0])
        // 7.0.1 语义：嵌套数组中的非对象元素使错误向上传播，整个属性回退声明默认值 []。
        let withBad = try XCTUnwrap(Host.deserialize(from: ["optional": [["id": 1], "bad", ["id": 2]] as [Any]]))
        XCTAssertEqual(withBad.optional.count, 0)
        XCTAssertEqual(withBad.optional.map { $0?.id }, [])
        XCTAssertEqual(withBad.optional.map { $0?.calls }, [])
        struct NestedHost: SmartCodableX {
            var rows: [[Child?]] = []
        }
        let nested = try XCTUnwrap(NestedHost.deserialize(from: ["rows": [[["id": 1], NSNull()] as [Any]]]))
        XCTAssertEqual(nested.rows.map { $0.map { $0?.id } }, [[1, nil]])
        struct Plain: SmartCodableX { var id = -1 }
        struct PlainHost: SmartCodableX { var plain: [Plain?] = [] }
        let plainNull = try XCTUnwrap(PlainHost.deserialize(from: ["plain": [["id": 1], NSNull(), ["id": 2]] as [Any]]))
        XCTAssertEqual(plainNull.plain.map { $0?.id }, [1, nil, 2])
        // 7.0.1 语义：嵌套数组中的非对象元素使整个属性回退声明默认值 []。
        let plainBad = try XCTUnwrap(PlainHost.deserialize(from: ["plain": [["id": 1], "bad", ["id": 2]] as [Any]]))
        XCTAssertEqual(plainBad.plain.map { $0?.id }, [])
    }
}

private struct Branch702CompactHost<Element: Codable>: SmartCodableX {
    @SmartCompact.Array var values: [Element] = []
}

private final class Branch702CallbackTrace {
    static let key = CodingUserInfoKey(rawValue: "Branch702CallbackTrace")!
    var callbacks: [Int] = []
    var events: [String] = []
}

private struct Branch702CallbackChild: SmartCodableX {
    var id = -1
    var calls = 0
    private var trace: Branch702CallbackTrace?

    enum CodingKeys: String, CodingKey { case id, calls }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        calls = try container.decodeIfPresent(Int.self, forKey: .calls) ?? 0
        trace = decoder.userInfo[Branch702CallbackTrace.key] as? Branch702CallbackTrace
        trace?.events.append("decoded:\(id)")
    }

    mutating func didFinishMapping() {
        trace?.callbacks.append(id)
        trace?.events.append("callback:\(id)")
        calls += 1
        id += 10
    }
}
