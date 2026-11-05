import Foundation
import SmartCodable

private struct DecodeOnly: SmartDecodable {
    var value: Int = 73
}

private struct EncodeOnly: SmartEncodable {
    var value: Int = 42
    mutating func didFinishMapping() {}
    static func mappingForKey() -> [SmartKeyTransformer]? { nil }
    static func mappingForValue() -> [SmartValueTransformer]? { nil }
}

private struct Combined: SmartCodableX, SmartDefaultValueKeyMapping {
    var value: Int = 73
    enum CodingKeys: String, CodingKey {
        case value = "json_value"
    }
    static let defaultValueKeyMapping = ["json_value": "value"]
}

private class ReferenceBase: SmartCodableX {
    var value: Int = 73
    required init() {}
}

private final class ReferenceChild: ReferenceBase {
    var extra: String = "child"
    required init() { super.init() }
    required init(from decoder: Decoder) throws { try super.init(from: decoder) }
}

private func verify(_ condition: @autoclosure () -> Bool, _ description: String) {
    guard condition() else {
        fatalError("Public API smoke failed: \(description)")
    }
}

verify(DecodeOnly.deserialize(from: [:])?.value == 73, "decode-only default")
verify(EncodeOnly().toDictionary()?["value"] as? Int == 42, "encode-only output")
verify(Combined.deserialize(from: [:])?.value == 73, "mapped default")
verify(Combined.deserialize(from: ["json_value": 9])?.value == 9, "combined decode")
verify(ReferenceBase.deserialize(from: ["value": 12])?.value == 12, "class decode")
verify(ReferenceChild.deserialize(from: ["value": 12]) != nil, "subclass compile and decode")
let decoder = SmartJSONDecoder()
decoder.smartUnkeyedDecodingStrategy = .consumeOnce
verify((try? decoder.smartDecode(DecodeOnly.self, from: [:] as [String: Any]))?.value == 73, "single-consumption option")
verify((try? decoder.smartDecode(Int.self, from: "5")) == 5, "decoder strategy API")
let encoder = SmartJSONEncoder()
encoder.smartDynamicValueEncodingStrategy = .recursive
verify((try? encoder.encode(EncodeOnly())) != nil, "encoder strategy API")
verify(((try? JSONSerialization.jsonObject(with: encoder.encode(EncodeOnly()), options: .fragmentsAllowed)) as? [String: Any])?["value"] as? Int == 42, "recursive option")
print("Public API smoke passed: 10 checks")
