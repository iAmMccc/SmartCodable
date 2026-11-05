import Foundation
import SmartCodable
import XCTest

private struct StructuredScalar: SmartCodableX {
    var value: Int8 = 73
}

private struct StructuredArray: SmartCodableX {
    var values: [Int] = []
}

/// Bounded, deterministic input construction. Version and seed are part of
/// the replay contract; test failures also print the exact generated payload.
private struct SemanticBytes {
    static let version = "lcg-v1"
    static let seed: UInt64 = 0xBADA_55C0_FFEE_0001
    private var state = seed

    mutating func next() -> UInt8 {
        state = state &* 2_862_933_555_777_941_757 &+ 3_037_000_493
        return UInt8(truncatingIfNeeded: state >> 32)
    }
}

final class StructuredSemanticTests: XCTestCase {
    func testBoundedScalarStatesAgainstIndependentExpectations() throws {
        var bytes = SemanticBytes()
        var distribution = [Int](repeating: 0, count: 5)
        for iteration in 0..<500 {
            let raw = bytes.next()
            let state = Int(bytes.next() % 5)
            distribution[state] += 1
            let validValue = Int8(bitPattern: raw)
            let expected: Int8
            let payload: [String: Any]
            switch state {
            case 0:
                payload = ["value": Int(validValue)]
                expected = validValue
            case 1:
                payload = ["value": String(validValue)]
                expected = validValue
            case 2:
                payload = [:]
                expected = 73
            case 3:
                payload = ["value": NSNull()]
                expected = 73
            default:
                payload = ["value": "invalid"]
                expected = 73
            }
            let actual = try XCTUnwrap(StructuredScalar.deserialize(from: payload))
            XCTAssertEqual(actual.value, expected,
                           "iteration=\(iteration) seed=\(SemanticBytes.seed) generator=\(SemanticBytes.version) "
                            + "state=\(state) raw=\(raw) payload=\(payload)")
        }
        XCTAssertTrue(distribution.allSatisfy { $0 > 0 }, "distribution=\(distribution)")
    }

    func testUnrelatedKeyDoesNotChangeKnownField() throws {
        var bytes = SemanticBytes()
        for iteration in 0..<160 {
            let value = Int8(bitPattern: bytes.next())
            let base = try XCTUnwrap(StructuredScalar.deserialize(from: ["value": String(value)]))
            let noisy = try XCTUnwrap(StructuredScalar.deserialize(from: [
                "value": String(value), "unused": ["tag": Int(bytes.next())]
            ]))
            XCTAssertEqual(base.value, value, "iteration=\(iteration) seed=\(SemanticBytes.seed)")
            XCTAssertEqual(noisy.value, base.value, "iteration=\(iteration) seed=\(SemanticBytes.seed)")
        }
    }

    func testMalformedArrayElementFallsBackToDeclaredDefault() throws {
        var bytes = SemanticBytes()
        for iteration in 0..<160 {
            let first = Int(bytes.next())
            let model = try XCTUnwrap(StructuredArray.deserialize(from: [
                "values": [first, NSNull(), first + 1]
            ]))
            // 7.0.1 语义：数组元素解码失败时错误向上传播，整个属性回退本模型自己的声明默认值。
            // 本模型声明默认值为 []，因此整个属性回退为 []。
            XCTAssertEqual(model.values, [],
                           "iteration=\(iteration) seed=\(SemanticBytes.seed) first=\(first)")
        }
    }
}
