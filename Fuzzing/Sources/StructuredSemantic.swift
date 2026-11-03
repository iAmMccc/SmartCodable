import Foundation
import SmartCodable

private struct StructuredProbe: SmartCodableX {
    var value: Int16 = 777
}

/// Version 1: first two bytes form an exact Int16; third byte selects JSON
/// number/string/missing/invalid string. Expected values come from these
/// bytes, never from SmartCodable's conversion implementation.
@_cdecl("LLVMFuzzerTestOneInput")
public func fuzzStructuredSemantic(_ input: UnsafePointer<UInt8>?, _ length: Int) -> Int32 {
    guard let input, length >= 3, length <= 64 else { return 0 }
    SmartSentinel.debugMode = .none
    let bits = UInt16(input[0]) | UInt16(input[1]) << 8
    let exact = Int16(bitPattern: bits)
    let mode = input[2] & 3
    let payload: [String: Any]
    let expected: Int16
    switch mode {
    case 0:
        payload = ["value": Int(exact)]
        expected = exact
    case 1:
        payload = ["value": String(exact)]
        expected = exact
    case 2:
        payload = [:]
        expected = 777
    default:
        payload = ["value": "invalid"]
        expected = 777
    }
    let actual = StructuredProbe.deserialize(from: payload)?.value
    guard actual == expected else {
        fatalError("structured-v1 bytes=\(Array(UnsafeBufferPointer(start: input, count: length))) expected=\(expected) actual=\(String(describing: actual))")
    }
    return 0
}
