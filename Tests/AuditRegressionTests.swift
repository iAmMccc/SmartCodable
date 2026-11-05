import XCTest
@testable import SmartCodable
#if canImport(Combine)
import Combine
#endif

private struct AuditUpperTransformer: ValueTransformable {
    typealias Object = String
    typealias JSON = String

    func transformFromJSON(_ value: Any) -> String? { (value as? String)?.uppercased() }
    func transformToJSON(_ value: String) -> String? { value.uppercased() }
}

private struct AuditTagTransformer: ValueTransformable {
    let tag: String
    typealias Object = Date
    typealias JSON = String

    func transformFromJSON(_ value: Any) -> Date? { nil }
    func transformToJSON(_ value: Date) -> String? { tag }
}

private final class DidFinishCounter {
    static var value = 0
}

private struct DidFinishChild: SmartCodableX {
    var n: Int = 0

    mutating func didFinishMapping() {
        DidFinishCounter.value += 1
        n += 100
    }
}

final class AuditRegressionTests: XCTestCase {

    override func tearDown() {
        SmartSentinel.debugMode = .none
        SmartSentinel.onLogGenerated { _ in }
        SmartCodableOptions.numberStrategy = .strict
        DidFinishCounter.value = 0
        super.tearDown()
    }

    // MARK: - Encoder

    func testTopLevelPrimitiveEncodingMatchesFoundation() throws {
        let encoder = SmartJSONEncoder()
        XCTAssertEqual(String(data: try encoder.encode(42), encoding: .utf8), "42")
        XCTAssertEqual(String(data: try encoder.encode(true), encoding: .utf8), "true")
        XCTAssertEqual(String(data: try encoder.encode("x"), encoding: .utf8), "\"x\"")
        XCTAssertEqual(String(data: try encoder.encode(Int?.none), encoding: .utf8), "null")
    }

    func testKeyStrategyStillAppliesValueTransformer() throws {
        struct Model: SmartCodableX {
            var userName: String = ""

            static func mappingForValue() -> [SmartValueTransformer]? {
                [CodingKeys.userName <--- AuditUpperTransformer()]
            }
        }

        let encoder = SmartJSONEncoder()
        encoder.smartKeyEncodingStrategy = .toSnakeCase
        let json = try XCTUnwrap(String(data: try encoder.encode(Model(userName: "mccc")), encoding: .utf8))
        XCTAssertEqual(json, "{\"user_name\":\"MCCC\"}")
    }

    func testTransformerIsMatchedByItsOwnMappingAlias() throws {
        struct Model: SmartCodableX {
            var createdAt: Date = Date(timeIntervalSince1970: 0)
            var expiredAt: Date = Date(timeIntervalSince1970: 1)

            static func mappingForValue() -> [SmartValueTransformer]? {
                [
                    CodingKeys.createdAt <--- AuditTagTransformer(tag: "CREATED"),
                    CodingKeys.expiredAt <--- AuditTagTransformer(tag: "EXPIRED")
                ]
            }

            static func mappingForKey() -> [SmartKeyTransformer]? {
                [CodingKeys.expiredAt <--- ["expired_at"]]
            }
        }

        let encoder = SmartJSONEncoder()
        encoder.userInfo[.init(rawValue: "Smart.useMappedKeys")!] = true
        let json = try XCTUnwrap(String(data: try encoder.encode(Model()), encoding: .utf8))
        XCTAssertTrue(json.contains("\"createdAt\":\"CREATED\""), json)
        XCTAssertTrue(json.contains("\"expired_at\":\"EXPIRED\""), json)
    }

    func testDictionaryAndOptionalElementsKeepValueTransformers() throws {
        struct Child: SmartCodableX {
            var name: String = ""

            static func mappingForValue() -> [SmartValueTransformer]? {
                [CodingKeys.name <--- AuditUpperTransformer()]
            }
        }
        struct Model: SmartCodableX {
            var map: [String: Child] = [:]
            var one: Child?
            var list: [Child?] = []
        }

        let model = Model(
            map: ["a": Child(name: "x")],
            one: Child(name: "y"),
            list: [Child(name: "z")]
        )
        let json = try XCTUnwrap(String(data: try SmartJSONEncoder().encode(model), encoding: .utf8))
        XCTAssertTrue(json.contains("\"name\":\"X\""), json)
        XCTAssertTrue(json.contains("\"name\":\"Y\""), json)
        XCTAssertTrue(json.contains("\"name\":\"Z\""), json)
    }

    // MARK: - Numeric boundaries

    func testIntegerBoundaryDoesNotTrap() {
        struct Model: SmartCodableX {
            var value: Int = 7
        }

        SmartCodableOptions.numberStrategy = .truncate
        XCTAssertEqual(Model.deserialize(from: "{\"value\":9223372036854775808}")?.value, 7)

        SmartCodableOptions.numberStrategy = .rounded
        XCTAssertEqual(Model.deserialize(from: "{\"value\":9223372036854775808}")?.value, 7)
    }

    func testNonFiniteFloatingPointStringFallsBackToDefault() {
        struct Model: SmartCodableX {
            var value: Double = 1.5
        }

        XCTAssertEqual(Model.deserialize(from: ["value": "inf"])?.value, 1.5)
        XCTAssertEqual(Model.deserialize(from: ["value": "nan"])?.value, 1.5)
        XCTAssertEqual(Model.deserialize(from: ["value": "1e400"])?.value, 1.5)
    }

    func testExplicitCodingKeyMappingRestoresDeclaredDefault() {
        struct Model: SmartCodableX, SmartDefaultValueKeyMapping {
            var age: Int = 18
            enum CodingKeys: String, CodingKey {
                case age = "user_age"
            }
            static let defaultValueKeyMapping = ["user_age": "age"]
        }

        XCTAssertEqual(Model.deserialize(from: [:])?.age, 18)
        XCTAssertEqual(Model.deserialize(from: ["user_age": NSNull()])?.age, 18)
        XCTAssertEqual(Model.deserialize(from: ["user_age": 5])?.age, 5)
    }

    // MARK: - Decoder

    // 用例意图：嵌套数组元素解码失败时，整个属性回退声明默认值而非保持元素位置
    func testNestedArrayFallsBackToDeclaredDefault() {
        struct Model: SmartCodableX {
            var values: [Int] = [7, 7, 7]
        }

        // 7.0.1 语义：嵌套数组的元素解码失败时错误向上传播，整个属性回退声明默认值 [7, 7, 7]。
        // 依据 7.0.1 oracle 探测输出（v701-full 基线）：
        //   CASE int-array-null result=[9]
        //   CASE int-array-null-default-777 result=[7,7,7]
        XCTAssertEqual(Model.deserialize(from: ["values": [1, NSNull(), 3]])?.values, [7, 7, 7])
    }

    func testStringFragmentDecodingMatchesDataInput() throws {
        let decoder = SmartJSONDecoder()
        XCTAssertEqual(try decoder.smartDecode(Int.self, from: "42"), 42)
        XCTAssertEqual(try decoder.smartDecode(Int.self, from: Data("42".utf8)), 42)
    }

    func testJSONValueKeepsIndexForUnsupportedValue() throws {
        let value = JSONValue.make([1, Date(), 2])
        guard case .array(let values) = value else {
            return XCTFail("expected array")
        }
        XCTAssertEqual(values, [.number("1"), .null, .number("2")])
    }

    func testUnsupportedDictionaryValueDoesNotBecomeExplicitNull() {
        guard case .object(let values) = JSONValue.make(["bad": Date(), "good": 1]) else {
            return XCTFail("expected object")
        }
        XCTAssertNil(values["bad"])
        XCTAssertEqual(values["good"], .number("1"))
    }

    func testDictionaryCanDecodeFromJSONStringValue() {
        struct Item: SmartCodableX {
            var n: Int = 0
        }
        struct Model: SmartCodableX {
            var map: [String: Item] = [:]
        }

        let model = Model.deserialize(from: ["map": "{\"k\":{\"n\":1}}"])
        XCTAssertEqual(model?.map["k"]?.n, 1)
    }

    // 7.0.1 语义：字典子模型默认不在字典解包路径触发完成回调。
    // 依据 7.0.1 oracle 探测输出：CASE dictionary-valid ids=[1,2] calls=[0,0] tally=0
    func testDictionaryElementsDoNotRunDidFinishMappingByDefault() {
        struct Model: SmartCodableX {
            var map: [String: DidFinishChild] = [:]
        }

        let model = Model.deserialize(from: ["map": ["a": ["n": 1], "b": ["n": 2]]])
        XCTAssertEqual(DidFinishCounter.value, 0)
        XCTAssertEqual(model?.map["a"]?.n, 1)
        XCTAssertEqual(model?.map["b"]?.n, 2)
    }

    func testCrossLevelMappingSkipsNullAlias() {
        struct Model: SmartCodableX {
            var value: Int = 18

            static func mappingForKey() -> [SmartKeyTransformer]? {
                [CodingKeys.value <--- ["a.b", "c"]]
            }
        }

        let model = Model.deserialize(from: ["a": ["b": NSNull()], "c": 5])
        XCTAssertEqual(model?.value, 5)
    }

    func testBlankDesignatedPathFailsInsteadOfReturningRoot() throws {
        struct Model: SmartCodableX {
            var name: String = ""
        }

        XCTAssertNil(Model.deserialize(from: ["name": "root"], designatedPath: " "))
        XCTAssertNil(Model.deserialize(from: ["name": "root"], designatedPath: "."))

        struct Named: SmartCodableX {
            var name: String = "dft"
        }
        let payload: [String: Any] = [
            "a": ["b": ["name": "x"]],
            "name": "root"
        ]
        let rejectedPaths = ["a.", ".a", "a. .b", "a..b"]
        var rejectedCases = 0
        for path in rejectedPaths {
            XCTAssertNil(Named.deserialize(from: payload, designatedPath: path), path)
            rejectedCases += 1
        }
        XCTAssertEqual(rejectedCases, 4)

        let nested = try XCTUnwrap(Named.deserialize(from: payload, designatedPath: "a.b"))
        XCTAssertEqual(nested.name, "x")
        let root = try XCTUnwrap(Named.deserialize(from: payload, designatedPath: ""))
        XCTAssertEqual(root.name, "root")
    }

    func testOptionalNullProducesNoLog() {
        struct Model: SmartCodableX {
            var age: Int? = nil
        }
        struct Req: SmartCodableX {
            var age: Int = 0
        }

        defer {
            SmartSentinel.debugMode = .none
            SmartSentinel.onLogGenerated { _ in }
        }

        SmartSentinel.debugMode = .verbose
        let noLog = expectation(description: "optional null is not an error")
        noLog.isInverted = true
        SmartSentinel.onLogGenerated { _ in noLog.fulfill() }

        _ = Model.deserialize(from: ["age": NSNull()])
        wait(for: [noLog], timeout: 0.3)

        let logged = expectation(description: "non-optional null logs")
        SmartSentinel.onLogGenerated { _ in logged.fulfill() }
        _ = Req.deserialize(from: ["age": NSNull()])
        wait(for: [logged], timeout: 1)
    }

    // MARK: - Property wrappers

    func testSmartCompactArrayDecodesPlainCodableElements() throws {
        struct Plain: Codable {
            var a: Int
        }
        struct Model: SmartCodableX {
            @SmartCompact.Array var items: [Plain] = []
        }

        let model = try XCTUnwrap(Model.deserialize(from: ["items": [["a": 1], ["a": 2]]]))
        XCTAssertEqual(model.items.map(\.a), [1, 2])
        let encoded = try XCTUnwrap(model.toDictionary())
        let items = try XCTUnwrap(encoded["items"] as? [[String: Int]])
        XCTAssertEqual(items.map { $0["a"] }, [1, 2])
    }

    func testSmartCompactArraySkipsInvalidScalarsWithoutAppendingDefaults() {
        struct Model: SmartCodableX {
            @SmartCompact.Array var ages: [Int] = []
        }

        let model = Model.deserialize(from: ["ages": ["Tom", 1, [:], 2, 3, "4"]])
        XCTAssertEqual(model?.ages, [1, 2, 3, 4])
    }

    func testSmartCompactArraySkipsInvalidDates() {
        struct Model: SmartCodableX {
            @SmartCompact.Array var dates: [Date] = []
        }

        let model = Model.deserialize(from: ["dates": ["invalid", 0]])
        XCTAssertEqual(model?.dates.count, 1)
        XCTAssertEqual(model?.dates.first?.timeIntervalSince1970, 0)
    }

    func testSmartCompactDictionaryEncodesAnyValues() throws {
        struct Model: SmartCodableX {
            @SmartCompact.Dictionary var info: [String: Any] = [:]
        }

        let model = try XCTUnwrap(Model.deserialize(from: [
            "info": ["a": 1, "b": "x", "c": ["n": 2]]
        ]))
        let dictionary = try XCTUnwrap(model.toDictionary())
        let info = try XCTUnwrap(dictionary["info"] as? [String: Any])

        XCTAssertEqual((info["a"] as? NSNumber)?.intValue, 1)
        XCTAssertEqual(info["b"] as? String, "x")
        XCTAssertEqual(((info["c"] as? [String: Any])?["n"] as? NSNumber)?.intValue, 2)
    }

    func testSmartAnyEncodesCodableRuntimeValues() throws {
        struct Model: SmartCodableX {
            @SmartAny var ts: Any? = Date(timeIntervalSince1970: 2)
            @SmartAny var data: Any? = Data([1, 2, 3])
        }

        let dictionary = try XCTUnwrap(Model().toDictionary())
        XCTAssertEqual((dictionary["ts"] as? NSNumber)?.doubleValue, -978307198)
        XCTAssertEqual(dictionary["data"] as? String, "AQID")
    }

    func testSmartAnyKeepsScientificAndLargeUnsignedNumbers() throws {
        struct Model: SmartCodableX {
            @SmartAny var scientific: Any?
            @SmartAny var big: Any?
        }

        let model = try XCTUnwrap(Model.deserialize(from: "{\"scientific\":1e-5,\"big\":18446744073709551615}"))
        let scientific = try XCTUnwrap(model.scientific as? NSNumber)
        let big = try XCTUnwrap(model.big as? NSNumber)
        XCTAssertEqual(scientific.decimalValue, Decimal(string: "0.00001"))
        XCTAssertEqual(big.stringValue, "18446744073709551615")
    }

    func testSmartDateRestoresDeclaredEncodeFormat() throws {
        struct Model: SmartCodableX {
            @SmartDate(wrappedValue: nil, encodeFormat: .timestampMilliseconds) var date: Date?
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let expected = try XCTUnwrap(formatter.date(from: "2024-01-02 03:04:05"))
        let model = try XCTUnwrap(Model.deserialize(from: ["date": "2024-01-02 03:04:05"]))
        let dictionary = try XCTUnwrap(model.toDictionary())
        XCTAssertEqual(try XCTUnwrap((dictionary["date"] as? NSNumber)?.int64Value), Int64(expected.timeIntervalSince1970 * 1000))

        let timestampModel = try XCTUnwrap(Model.deserialize(from: ["date": 1_700_000_000]))
        let timestampDictionary = try XCTUnwrap(timestampModel.toDictionary())
        XCTAssertEqual((timestampDictionary["date"] as? NSNumber)?.int64Value, 1_700_000_000_000)
    }

    func testSmartDateTreatsExactSecondThresholdAsSeconds() throws {
        struct Model: SmartCodableX {
            var date: Date = Date(timeIntervalSince1970: 0)
        }

        let model = Model.deserialize(from: ["date": 1_000_000_000_000])
        // 7.0.1 语义：毫秒阈值为 double > 1_000_000_000_000，恰好 1e12 按秒解析。
        XCTAssertEqual(model?.date.timeIntervalSince1970, 1_000_000_000_000)

        let belowThreshold = try XCTUnwrap(Model.deserialize(from: ["date": 999_999_999_999]))
        XCTAssertEqual(belowThreshold.date.timeIntervalSince1970, 999_999_999_999)

        let aboveThreshold = try XCTUnwrap(Model.deserialize(from: ["date": 1_000_000_000_001]))
        XCTAssertEqual(aboveThreshold.date.timeIntervalSince1970, 1_000_000_000.001, accuracy: 1e-6)
    }

    func testURLTransformerDoesNotDoubleEncode() {
        let input = "https://example.com/%E4%B8%AD%E6%96%87/a%20b#frag"
        let url = SmartURLTransformer().transformFromJSON(input)
        XCTAssertEqual(url?.absoluteString, input)
    }

    func testNestedContainerWritesFlatValueIntoNestedObject() throws {
        struct FlatUser: SmartCodableX {
            var accid: String = ""
        }
        struct Inner: Encodable {
            enum Keys: String, CodingKey {
                case sub
                case flat
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: Keys.self)
                var nested = container.nestedContainer(keyedBy: Keys.self, forKey: .sub)
                try nested.encode(SmartFlat(wrappedValue: FlatUser(accid: "a")), forKey: .flat)
            }
        }
        struct Host: Encodable {
            var inner: Inner = Inner()
        }

        let json = try XCTUnwrap(String(data: try SmartJSONEncoder().encode(Host()), encoding: .utf8))
        XCTAssertEqual(json, "{\"inner\":{\"sub\":{\"accid\":\"a\"}}}")
    }

    #if canImport(Combine)
    func testSmartPublishedAssignsWithCustomObjectWillChangePublisher() {
        final class Model: ObservableObject {
            let objectWillChange = PassthroughSubject<Void, Never>()
            @SmartPublished var score: Int = 7
        }

        let model = Model()
        model.score = 42
        XCTAssertEqual(model.score, 42)
    }
    #endif

    // MARK: - Updater

    func testUpdaterAcceptsAnyDeclaredAlias() {
        struct Model: SmartCodableX {
            var name: String = ""

            static func mappingForKey() -> [SmartKeyTransformer]? {
                [CodingKeys.name <--- ["json_name", "alt_name"]]
            }
        }

        var model = Model(name: "old")
        SmartUpdater.update(&model, from: ["alt_name": "new"])
        XCTAssertEqual(model.name, "new")
    }

    func testUpdaterPreservesMappingPriorityWhenBothAliasesArePresent() {
        struct Model: SmartCodableX {
            var name: String = ""

            static func mappingForKey() -> [SmartKeyTransformer]? {
                [CodingKeys.name <--- ["json_name", "alt_name"]]
            }
        }

        var model = Model(name: "old")
        SmartUpdater.update(&model, from: ["json_name": "preferred", "alt_name": "fallback"])
        XCTAssertEqual(model.name, "preferred")
    }

    func testUpdaterSkipsNullHigherPriorityAlias() {
        struct Model: SmartCodableX {
            var name: String = ""

            static func mappingForKey() -> [SmartKeyTransformer]? {
                [CodingKeys.name <--- ["json_name", "alt_name"]]
            }
        }

        var model = Model(name: "old")
        SmartUpdater.update(&model, from: ["json_name": NSNull(), "alt_name": "new"])
        XCTAssertEqual(model.name, "new")
    }

    func testUpdaterAcceptsNestedPathAliasOverOldValue() {
        struct Model: SmartCodableX {
            var name: String = ""

            static func mappingForKey() -> [SmartKeyTransformer]? {
                [CodingKeys.name <--- ["data.name", "alt"]]
            }
        }

        var model = Model(name: "old")
        SmartUpdater.update(&model, from: ["data": ["name": "new"]])
        XCTAssertEqual(model.name, "new")
    }

    func testUpdaterDoesNotResetWhenEncodingFails() {
        struct Model: SmartCodableX {
            var value: Double = 1
            @SmartIgnored var token: String = "declared"
        }

        var model = Model(value: .nan, token: "runtime")
        SmartUpdater.update(&model, from: ["value": 2])
        XCTAssertEqual(model.token, "runtime")
        XCTAssertTrue(model.value.isNaN)
    }

    func testUpdaterPreservingHookKeepsExcludedRuntimeState() {
        struct Model: SmartCodableX {
            var value: Int = 0
            var local: String = "declared"
            @SmartIgnored var token: String = "declared"

            enum CodingKeys: String, CodingKey {
                case value
            }
        }

        var model = Model()
        model.local = "runtime-local"
        model.token = "runtime-token"
        SmartUpdater.update(&model, from: ["value": 2]) { updated, old in
            updated.local = old.local
            updated.token = old.token
        }
        XCTAssertEqual(model.value, 2)
        XCTAssertEqual(model.local, "runtime-local")
        XCTAssertEqual(model.token, "runtime-token")
    }

    func testUpdaterPreservingHookWorksForStringAndDataInputs() {
        struct Model: SmartCodableX {
            var value: Int = 0
            @SmartIgnored var token: String = "declared"
        }

        var model = Model(value: 1, token: "runtime")
        let restore: (inout Model, Model) -> Void = { updated, old in
            updated.token = old.token
        }
        SmartUpdater.update(&model, from: "{\"value\":2}", preserving: restore)
        XCTAssertEqual(model.value, 2)
        XCTAssertEqual(model.token, "runtime")

        SmartUpdater.update(&model, from: Data("{\"value\":3}".utf8), preserving: restore)
        XCTAssertEqual(model.value, 3)
        XCTAssertEqual(model.token, "runtime")
    }

    // MARK: - Sentinel cache

    func testLogCacheSeparatesKebabKeyFromNestedPath() throws {
        let cache = LogCache()
        let mark = "AuditMark"
        let userDashName = _JSONKey(stringValue: "user-name", intValue: nil)
        let user = _JSONKey(stringValue: "user", intValue: nil)
        let name = _JSONKey(stringValue: "name", intValue: nil)
        let field = _JSONKey(stringValue: "field", intValue: nil)

        cache.save(
            error: .keyNotFound(field, .init(codingPath: [userDashName, field], debugDescription: "x")),
            className: "DashContainer",
            parsingMark: mark
        )
        cache.save(
            error: .keyNotFound(field, .init(codingPath: [user, name, field], debugDescription: "x")),
            className: "NestedContainer",
            parsingMark: mark
        )

        let output = try XCTUnwrap(cache.formatLogs(parsingMark: mark))
        let missingKey = "field: No value associated with key."
        XCTAssertEqual(output.components(separatedBy: missingKey).count - 1, 2, output)
        XCTAssertEqual(output.components(separatedBy: "DashContainer").count - 1, 1, output)
        XCTAssertTrue(output.contains("NestedContainer"), output)
    }
}
