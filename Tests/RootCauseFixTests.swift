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

    private struct Alias: SmartCodableX {
        var firstName = "old-first"
        var name = "old-full"
        static func mappingForKey() -> [SmartKeyTransformer]? {
            [CodingKeys.firstName <--- ["name", "first_name"]]
        }
    }

    func testUpdaterMergesByFieldIdentityAcrossAllEntrypoints() {
        let json = "{\"first_name\":\"new-first\"}"
        var dictionary = Alias(), string = Alias(), data = Alias()
        SmartUpdater.update(&dictionary, from: ["first_name": "new-first"])
        SmartUpdater.update(&string, from: json)
        SmartUpdater.update(&data, from: Data(json.utf8))
        for model in [dictionary, string, data] {
            XCTAssertEqual(model.firstName, "new-first")
            XCTAssertEqual(model.name, "old-full")
        }
        var empty = Alias()
        SmartUpdater.update(&empty, from: [:])
        XCTAssertEqual(empty.firstName, "old-first")
        XCTAssertEqual(empty.name, "old-full")
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

    func testDecodeKeepsSessionMetadataOutOfCallerConfiguration() throws {
        struct Model: Decodable {
            let mark: String
            init(from decoder: Decoder) throws {
                mark = decoder.userInfo[CodingUserInfoKey.parsingMark!] as? String ?? "missing"
            }
        }
        let decoder = SmartJSONDecoder()
        let callerKey = CodingUserInfoKey(rawValue: "caller")!
        decoder.userInfo[callerKey] = "retained"
        let first = try decoder.smartDecode(Model.self, from: [:] as [String: Int])
        let second = try decoder.smartDecode(Model.self, from: [:] as [String: Int])
        XCTAssertNotEqual(first.mark, "missing")
        XCTAssertNotEqual(first.mark, second.mark)
        XCTAssertNil(decoder.userInfo[CodingUserInfoKey.parsingMark!])
        XCTAssertEqual(decoder.userInfo[callerKey] as? String, "retained")
    }
}

extension RootCauseFixTests {
    private struct Positive: Decodable {
        let value: Int
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            value = try container.decode(Int.self)
            guard value > 0 else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "positive required")
            }
        }
    }
    private struct Cursor: SmartCodableX {
        var values: [Int?] = []
        var indices: [Int] = []
        init() {}
        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            while !container.isAtEnd {
                values.append(try container.decodeIfPresent(Positive.self)?.value)
                indices.append(container.currentIndex)
            }
            if let impl = decoder as? JSONDecoderImpl,
               impl.options.unkeyedDecodingStrategy == .consumeOnce {
                XCTAssertThrowsError(try container.decodeIfPresent(Positive.self))
                XCTAssertEqual(container.currentIndex, indices.last)
            }
        }
    }

    func testSingleConsumptionOptInKeepsDefaultLegacyResults() throws {
        let legacy = try XCTUnwrap(Cursor.deserialize(from: "[0,2,3]"))
        XCTAssertEqual(legacy.values, [nil, 3])
        XCTAssertEqual(legacy.indices, [2, 3])
        let decoder = SmartJSONDecoder()
        decoder.smartUnkeyedDecodingStrategy = .consumeOnce
        for input in ["[0,2,3]", "[null,2,3]", "[\"bad\",2,3]"] {
            let optedIn = try XCTUnwrap(decoder.smartDecode(Cursor.self, from: input))
            XCTAssertEqual(optedIn.values, [nil, 2, 3])
            XCTAssertEqual(optedIn.indices, [1, 2, 3])
        }
        XCTAssertEqual(try decoder.smartDecode(Cursor.self, from: "[0]").values, [nil])
    }

    func testSingleConsumptionPropagatesToNestedModels() throws {
        struct Host: SmartCodableX { var values = Cursor() }
        let decoder = SmartJSONDecoder()
        decoder.smartUnkeyedDecodingStrategy = .consumeOnce
        let host = try XCTUnwrap(decoder.smartDecode(Host.self, from: ["values": [0, 2, 3]] as [String: Any]))
        XCTAssertEqual(host.values.values, [nil, 2, 3])
    }

    private struct Dynamic: SmartCodableX {
        var rawValue = "child"
        static func mappingForValue() -> [SmartValueTransformer]? { [CodingKeys.rawValue <--- Upper()] }
        static func mappingForKey() -> [SmartKeyTransformer]? { [CodingKeys.rawValue <--- "encoded_name"] }
    }
    private struct DynamicHost: SmartCodableX {
        @SmartAny var payload: Any? = [
            "dataKey": [
                "date": Date(timeIntervalSince1970: 2),
                "data": Data([1, 2, 3]),
                "url": URL(string: "https://example.com/a")!,
                "model": Dynamic(),
                "array": [Optional(Dynamic()) as Any, NSNull()]
            ] as [String: Any]
        ] as [String: Any]
        @SmartCompact.Dictionary var compact: [String: Any] = ["nested": ["model": Dynamic()] as [String: Any]]
    }

    func testRecursiveDynamicOptInPreservesStrategiesSnapshotsAndDataKeys() throws {
        let encoder = SmartJSONEncoder()
        encoder.smartDynamicValueEncodingStrategy = .recursive
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.smartKeyEncodingStrategy = .toSnakeCase
        encoder.userInfo[CodingUserInfoKey.useMappedKeys!] = true
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(DynamicHost())) as? [String: Any])
        let payload = try XCTUnwrap(json["payload"] as? [String: Any])
        XCTAssertNil(payload["data_key"])
        let nested = try XCTUnwrap(payload["dataKey"] as? [String: Any])
        XCTAssertEqual((nested["date"] as? NSNumber)?.intValue, 2000)
        XCTAssertEqual(nested["data"] as? String, "AQID")
        XCTAssertEqual(nested["url"] as? String, "https://example.com/a")
        XCTAssertEqual(nested["model"] as? [String: String], ["encoded_name": "CHILD"])
        let array = try XCTUnwrap(nested["array"] as? [Any])
        XCTAssertEqual(array.count, 2)
        XCTAssertEqual(array[0] as? [String: String], ["encoded_name": "CHILD"])
        XCTAssertTrue(array[1] is NSNull)
        let compact = try XCTUnwrap(json["compact"] as? [String: Any])
        XCTAssertEqual((compact["nested"] as? [String: Any])?["model"] as? [String: String], ["encoded_name": "CHILD"])
        let convenienceEncoder = SmartJSONEncoder()
        convenienceEncoder.smartDynamicValueEncodingStrategy = .recursive
        let convenienceData = try convenienceEncoder.encode(DynamicHost())
        let throughInstance = try XCTUnwrap(JSONSerialization.jsonObject(with: convenienceData, options: .fragmentsAllowed) as? [String: Any])
        XCTAssertNotNil((throughInstance["payload"] as? [String: Any])?["dataKey"])
    }

    func testRecursiveDynamicReportsUnsupportedLeafAtItsActualPath() throws {
        struct Opaque {}
        struct Host: SmartCodableX { @SmartAny var payload: Any? = ["nested": ["opaque": Opaque()]] }
        let encoder = SmartJSONEncoder()
        encoder.smartDynamicValueEncodingStrategy = .recursive
        XCTAssertThrowsError(try encoder.encode(Host())) { error in
            guard case EncodingError.invalidValue(_, let context) = error else { return XCTFail("\(error)") }
            XCTAssertEqual(context.codingPath.map(\.stringValue), ["payload", "nested", "opaque"])
        }
    }

    func testUpdaterKeepsNestedMappingsAndPrimaryAliasNullFallback() {
        struct Child: SmartCodableX {
            var name = "declared"
            static func mappingForKey() -> [SmartKeyTransformer]? { [CodingKeys.name <--- ["json_name", "alt"]] }
        }
        struct Host: SmartCodableX {
            var child = Child(name: "retained")
            var value = "declared"
            static func mappingForKey() -> [SmartKeyTransformer]? { [CodingKeys.value <--- ["primary", "alt"]] }
        }
        var host = Host(child: Child(name: "retained"), value: "runtime")
        SmartUpdater.update(&host, from: ["primary": NSNull()])
        XCTAssertEqual(host.value, "declared")
        XCTAssertEqual(host.child.name, "retained")
        SmartUpdater.update(&host, from: ["child": ["json_name": "new"]])
        XCTAssertEqual(host.child.name, "new")
    }

    func testConcurrentSharedDecoderSessionsStayDistinctWithFixedConfiguration() throws {
        struct Model: Decodable {
            let mark: String
            let value: Int
            init(from decoder: Decoder) throws {
                mark = decoder.userInfo[CodingUserInfoKey.parsingMark!] as? String ?? "missing"
                let c = try decoder.singleValueContainer()
                value = try c.decode(Int.self)
            }
        }
        let decoder = SmartJSONDecoder()
        let lock = NSLock()
        var results: [(Int, Model?)] = []
        DispatchQueue.concurrentPerform(iterations: 128) { index in
            let result = try? decoder.smartDecode(Model.self, from: String(index))
            lock.lock()
            results.append((index, result))
            lock.unlock()
        }
        XCTAssertEqual(results.count, 128)
        var marks = Set<String>()
        for (input, value) in results {
            let model = try XCTUnwrap(value)
            XCTAssertEqual(model.value, input)
            XCTAssertNotEqual(model.mark, "missing")
            marks.insert(model.mark)
        }
        XCTAssertEqual(marks.count, 128)
        XCTAssertNil(decoder.userInfo[CodingUserInfoKey.parsingMark!])
    }
}

extension RootCauseFixTests {
    func testSharedDecoderConcurrentLogsKeepOneSessionPerCall() {
        struct SharedLogged: SmartCodableX { var id = -1; var value = 7 }
        let oldMode = SmartSentinel.debugMode
        defer {
            SmartSentinel.debugMode = oldMode
            SmartSentinel.onLogGenerated { _ in }
        }
        SmartSentinel.debugMode = .alert
        let completed = expectation(description: "each session flushes its own log")
        completed.expectedFulfillmentCount = 64
        let lock = NSLock()
        var messages: [String] = []
        var results: [(Int, SharedLogged?)] = []
        SmartSentinel.onLogGenerated { message in
            lock.lock()
            messages.append(message)
            lock.unlock()
            completed.fulfill()
        }
        let decoder = SmartJSONDecoder()
        DispatchQueue.concurrentPerform(iterations: 64) { index in
            let value = try? decoder.smartDecode(SharedLogged.self, from: ["id": index, "value": "bad"])
            lock.lock()
            results.append((index, value))
            lock.unlock()
        }
        wait(for: [completed], timeout: 5)
        XCTAssertEqual(messages.count, 64)
        for message in messages {
            XCTAssertTrue(message.contains("SharedLogged"))
            XCTAssertEqual(message.components(separatedBy: "[Smart Sentinel]").count - 1, 1)
        }
        XCTAssertEqual(results.count, 64)
        for (index, result) in results {
            XCTAssertEqual(result?.id, index)
            XCTAssertEqual(result?.value, 7)
        }
    }
}

extension RootCauseFixTests {
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
        var model = Model()
        SmartUpdater.update(&model, from: ["first_name": "new-first"])
        XCTAssertEqual(model.firstName, "new-first")
        XCTAssertEqual(model.name, "independent")
    }
}

extension RootCauseFixTests {
    // Isolate the successful fallback branch independently of standard scalar
    // Decodable implementations, which may recover before this branch is reached.
    private struct FallbackValue: Decodable, TypeTransformable {
        let value: String
        init(value: String) { self.value = value }
        init(from decoder: Decoder) throws { throw Expected.failure }
        static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> FallbackValue? {
            guard case .string(let text) = value, text != "bad" else { return nil }
            return FallbackValue(value: text.uppercased())
        }
    }

    func testSingleConsumptionHandlesBothSuccessfulAndFailedFallback() throws {
        struct Sequence: Decodable {
            var values: [String?] = []
            var indices: [Int] = []
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                while !container.isAtEnd {
                    values.append(try container.decodeIfPresent(FallbackValue.self)?.value)
                    indices.append(container.currentIndex)
                }
            }
        }
        let decoder = SmartJSONDecoder()
        decoder.smartUnkeyedDecodingStrategy = .consumeOnce
        let result = try decoder.smartDecode(Sequence.self, from: "[\"bad\",\"second\",\"third\"]")
        XCTAssertEqual(result.values, [nil, "SECOND", "THIRD"])
        XCTAssertEqual(result.indices, [1, 2, 3])
    }
}
