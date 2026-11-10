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

private struct BooleanIntegerModel: SmartDecodable {
    var value: Int = 73
}

private var checks = 0

private func verify(_ condition: @autoclosure () -> Bool, _ description: String) {
    guard condition() else {
        fatalError("Public API smoke failed: \(description)")
    }
    checks += 1
}

private func decodingOptionIsExhaustive(_ option: SmartDecodingOption) -> Bool {
    switch option {
    case .date: return true
    case .data: return true
    case .float: return true
    case .key: return true
    case .logContext: return true
    }
}

private func encodingOptionIsExhaustive(_ option: SmartEncodingOption) -> Bool {
    switch option {
    case .date: return true
    case .data: return true
    case .float: return true
    case .key: return true
    }
}

private func encodesJSONNumber(_ value: Int) -> Bool {
    var model = EncodeOnly()
    model.value = value
    guard let data = try? SmartJSONEncoder().encode(model),
          let number = ((try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)) as? [String: Any])?["value"] as? NSNumber else {
        return false
    }
    return CFGetTypeID(number) != CFBooleanGetTypeID() && number.intValue == value
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
verify((try? decoder.smartDecode(Int.self, from: Data("5".utf8))) == 5, "decoder strategy API with explicit fragment input")
let rejectsLegacyStringFragment: Bool
do {
    _ = try decoder.smartDecode(Int.self, from: "5")
    rejectsLegacyStringFragment = false
} catch DecodingError.dataCorrupted {
    rejectsLegacyStringFragment = true
} catch {
    rejectsLegacyStringFragment = false
}
verify(rejectsLegacyStringFragment, "legacy String fragment boundary")
let encoder = SmartJSONEncoder()
encoder.smartDynamicValueEncodingStrategy = .recursive
verify((try? encoder.encode(EncodeOnly())) != nil, "encoder strategy API")
verify(((try? JSONSerialization.jsonObject(with: encoder.encode(EncodeOnly()), options: .fragmentsAllowed)) as? [String: Any])?["value"] as? Int == 42, "recursive option")
let legacyBooleanDecoder = SmartJSONDecoder()
let enabledBooleanDecoder = SmartJSONDecoder()
enabledBooleanDecoder.smartBooleanToIntegerDecodingStrategy = .zeroOrOne
verify((try? legacyBooleanDecoder.smartDecode(BooleanIntegerModel.self, from: "{\"value\":true}"))?.value == 73, "legacy decoder keeps default for true")
verify((try? legacyBooleanDecoder.smartDecode(BooleanIntegerModel.self, from: "{\"value\":false}"))?.value == 73, "legacy decoder keeps default for false")
verify((try? enabledBooleanDecoder.smartDecode(BooleanIntegerModel.self, from: Data("{\"value\":true}".utf8)))?.value == 1, "opt-in true decodes to 1")
verify((try? enabledBooleanDecoder.smartDecode(BooleanIntegerModel.self, from: Data("{\"value\":false}".utf8)))?.value == 0, "opt-in false decodes to 0")
verify((try? enabledBooleanDecoder.smartDecode(Int.self, from: Data("true".utf8))) == 1, "opt-in fragment true decodes to 1")
verify((try? enabledBooleanDecoder.smartDecode(Int.self, from: Data("false".utf8))) == 0, "opt-in fragment false decodes to 0")
verify(BooleanIntegerModel.deserialize(from: "{\"value\":true}")?.value == 73, "deserialize keeps default for true")
verify(BooleanIntegerModel.deserialize(from: "{\"value\":false}")?.value == 73, "deserialize keeps default for false")
verify(decodingOptionIsExhaustive(.logContext(header: "h", footer: "f")), "decoding option exhaustive switch")
verify(encodingOptionIsExhaustive(.date(.iso8601)), "encoding option exhaustive switch")
verify(encodesJSONNumber(1), "integer 1 encodes as JSON number")
verify(encodesJSONNumber(0), "integer 0 encodes as JSON number")
print("Public API smoke passed: \(checks) checks")
