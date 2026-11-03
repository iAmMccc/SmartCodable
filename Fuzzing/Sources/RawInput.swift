import Foundation
import SmartCodable

private struct RawInputProbe: SmartCodableX {
    var value: Int = 77
}

/// Invalid JSON is allowed to throw. This target checks crashes and hangs;
/// StructuredSemantic checks decoded values independently.
@_cdecl("LLVMFuzzerTestOneInput")
public func fuzzRawInput(_ input: UnsafePointer<UInt8>?, _ length: Int) -> Int32 {
    guard let input, length <= 512 else { return 0 }
    SmartSentinel.debugMode = .none
    _ = RawInputProbe.deserialize(from: Data(bytes: input, count: length))
    return 0
}
