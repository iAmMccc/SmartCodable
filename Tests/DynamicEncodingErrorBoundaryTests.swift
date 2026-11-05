import Foundation
import SmartCodable
import XCTest

final class DynamicEncodingErrorBoundaryTests: XCTestCase {
    private final class Events { var values: [String] = [] }
    private enum Expected: Error { case leaf }
    private struct Plain: Encodable {
        let events: Events
        func encode(to encoder: Encoder) throws {
            events.values.append("plain")
            throw Expected.leaf
        }
    }
    private struct Smart: SmartCodableX {
        var events: Events? = nil
        private enum CodingKeys: CodingKey {}
        func encode(to encoder: Encoder) throws {
            events?.values.append("smart")
            throw Expected.leaf
        }
    }
    private struct AnyHost: SmartCodableX { @SmartAny var value: Any = 0 }
    private struct CompactHost<T>: SmartCodableX { @SmartCompact.Array var values: [T] = [] }

    func testDefaultSmartAnyDoesNotInvokeUnknownEncodableButRecursivePropagates() throws {
        let events = Events()
        var host = AnyHost(); host.value = Plain(events: events)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: SmartJSONEncoder().encode(host)) as? [String: Any])
        XCTAssertEqual(object.count, 1)
        XCTAssertTrue(object["value"] is NSNull)
        XCTAssertEqual(events.values, [])

        let encoder = SmartJSONEncoder()
        encoder.smartDynamicValueEncodingStrategy = .recursive
        XCTAssertThrowsError(try encoder.encode(host)) { XCTAssertTrue($0 is Expected) }
        XCTAssertEqual(events.values, ["plain"])
    }

    func testDefaultSmartAnyStillPropagatesSupportedModelError() throws {
        let events = Events()
        var host = AnyHost(); host.value = Smart(events: events)
        XCTAssertThrowsError(try SmartJSONEncoder().encode(host)) { XCTAssertTrue($0 is Expected) }
        XCTAssertEqual(events.values, ["smart"])
    }

    func testCompactPlainErrorIsInvokedOnlyByConversionOptIn() throws {
        let previous = SmartCodableOptions.compactElementStrategy
        defer { SmartCodableOptions.compactElementStrategy = previous }
        let events = Events()
        var host = CompactHost<Plain>(); host.values = [Plain(events: events)]
        SmartCodableOptions.compactElementStrategy = .legacy
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: SmartJSONEncoder().encode(host)) as? [String: Any])
        XCTAssertEqual((object["values"] as? [Any])?.count, 1)
        XCTAssertTrue((object["values"] as? [Any])?.first is NSNull)
        XCTAssertEqual(events.values, [])
        SmartCodableOptions.compactElementStrategy = .convert
        XCTAssertThrowsError(try SmartJSONEncoder().encode(host)) { XCTAssertTrue($0 is Expected) }
        XCTAssertEqual(events.values, ["plain"])
    }

    func testCompactSmartModelKeepsItsOwnHistoricalErrorBoundary() throws {
        let previous = SmartCodableOptions.compactElementStrategy
        defer { SmartCodableOptions.compactElementStrategy = previous }
        let events = Events()
        var host = CompactHost<Smart>(); host.values = [Smart(events: events)]
        SmartCodableOptions.compactElementStrategy = .legacy
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: SmartJSONEncoder().encode(host)) as? [String: Any])
        XCTAssertEqual((object["values"] as? [Any])?.count, 1)
        XCTAssertTrue((object["values"] as? [Any])?.first is NSNull)
        XCTAssertEqual(events.values, ["smart"])
        events.values = []
        SmartCodableOptions.compactElementStrategy = .convert
        XCTAssertThrowsError(try SmartJSONEncoder().encode(host)) { XCTAssertTrue($0 is Expected) }
        XCTAssertEqual(events.values, ["smart"])
    }
}
