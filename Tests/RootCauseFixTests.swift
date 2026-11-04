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
