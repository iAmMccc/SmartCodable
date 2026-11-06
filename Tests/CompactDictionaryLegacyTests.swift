import Foundation
import SmartCodable
import XCTest

private final class CompactDictionaryTrace {
    var encodes = 0
}

private enum CompactDictionaryFailure: Error {
    case expected
}

private struct CompactDictionaryThrowingValue: Encodable {
    let trace: CompactDictionaryTrace

    func encode(to encoder: Encoder) throws {
        trace.encodes += 1
        throw CompactDictionaryFailure.expected
    }
}

final class CompactDictionaryLegacyTests: XCTestCase {
    private struct Host: SmartCodableX {
        @SmartCompact.Dictionary var payload: [String: Any] = [:]
    }

    func testDefaultCompactDictionaryKeepsHistoricalRuntimeAcceptanceDomain() throws {
        var model = Host()
        model.payload = [
            "heterogeneousObject": ["x": 1] as [String: Any],
            "heterogeneousArray": [1, "x"] as [Any],
            "nestedDate": ["date": Date(timeIntervalSince1970: 0)] as [String: Any],
            "null": NSNull(),
            "number": 7,
            "text": "kept",
            "typedObject": ["x": 1],
            "typedArray": [1, 2],
            "date": Date(timeIntervalSince1970: 2)
        ]
        let encoder = SmartJSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let actual = try JSONSerialization.jsonObject(with: encoder.encode(model))
        let expected = try JSONSerialization.jsonObject(with: Data(
            #"{"payload":{"number":7,"text":"kept","typedObject":{"x":1},"typedArray":[1,2],"date":2000}}"#.utf8
        ))
        XCTAssertEqual(try canonical(actual), try canonical(expected))
    }

    func testDefaultCompactDictionaryInvokesSupportedEncodableAndPropagatesItsError() throws {
        let trace = CompactDictionaryTrace()
        var model = Host()
        model.payload = ["value": CompactDictionaryThrowingValue(trace: trace)]
        let encoder = SmartJSONEncoder()
        XCTAssertThrowsError(try encoder.encode(model)) { error in
            guard case CompactDictionaryFailure.expected = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(trace.encodes, 1)

        model.payload = ["value": 7]
        let actual = try JSONSerialization.jsonObject(with: encoder.encode(model))
        let expected = try JSONSerialization.jsonObject(with: Data(#"{"payload":{"value":7}}"#.utf8))
        XCTAssertEqual(try canonical(actual), try canonical(expected))
        XCTAssertEqual(trace.encodes, 1)
    }

    private func canonical(_ value: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
    }
}
