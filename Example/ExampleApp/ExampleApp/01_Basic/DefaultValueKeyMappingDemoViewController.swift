import UIKit
import SmartCodable

/// 重命名键的声明默认值，以及 @SmartDate / @SmartHexColor 在 CodingKeys 重命名后的编码。
final class DefaultValueKeyMappingDemoViewController: DemoBaseViewController {

    struct NameModel: SmartCodableX, SmartDefaultValueKeyMapping {
        var userName = "dft"
        enum CodingKeys: String, CodingKey { case userName = "user_name" }
        static let defaultValueKeyMapping = ["user_name": "userName"]
    }

    struct DateModel: SmartCodableX, SmartDefaultValueKeyMapping {
        @SmartDate(wrappedValue: nil, encodeFormat: .timestampMilliseconds) var createdAt: Date?
        enum CodingKeys: String, CodingKey { case createdAt = "created_at" }
        static let defaultValueKeyMapping = ["created_at": "createdAt"]
    }

    struct ColorModel: SmartCodableX, SmartDefaultValueKeyMapping {
        @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rrggbb(.hash)) var colorValue: ColorObject?
        enum CodingKeys: String, CodingKey { case colorValue = "color_value" }
        static let defaultValueKeyMapping = ["color_value": "colorValue"]
    }

    struct RoundTripColorModel: SmartCodableX {
        @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rrggbbaa(.none)) var c: ColorObject?
    }

    struct HashColorModel: SmartCodableX {
        @SmartHexColor(wrappedValue: nil, encodeHexFormat: .rrggbb(.hash)) var c: ColorObject?
    }

    override var defaultJSON: String { "{}" }

    override func run(with json: String) -> [String] {
        var report = DemoReport(unjudgedPrefix: json == defaultJSON ? 0 : 1)
        report.add(
            input: json,
            api: "NameModel.deserialize(from:).userName",
            expected: "dft",
            actual: userName(json)
        )
        report.add(
            input: #"{"user_name":null}"#,
            api: "NameModel.deserialize(from:).userName",
            expected: "dft",
            actual: userName(#"{"user_name":null}"#)
        )
        report.add(
            input: #"{"user_name":"ada"}"#,
            api: "NameModel.deserialize(from:).userName",
            expected: "ada",
            actual: userName(#"{"user_name":"ada"}"#)
        )
        let dateJSON = #"{"created_at":1700000000}"#
        report.add(
            input: dateJSON,
            api: "DateModel.deserialize(from:).toDictionary()[\"created_at\"]",
            expected: "1700000000000",
            actual: createdAt(dateJSON)
        )
        let colorJSON = #"{"color_value":"FF0000"}"#
        report.add(
            input: colorJSON,
            api: "ColorModel.deserialize(from:).toDictionary()[\"color_value\"]",
            expected: "#FF0000",
            actual: colorValue(colorJSON)
        )
        for hex in ["80808080", "7F7F7F7F", "01020304", "12AB34CD", "FFFFFF00"] {
            let input = "{\"c\":\"\(hex)\"}"
            report.add(
                input: input,
                api: "RoundTripColorModel.deserialize(from:).toDictionary()[\"c\"]",
                expected: hex,
                actual: encodedC(RoundTripColorModel.deserialize(from: input))
            )
        }
        let hashJSON = #"{"c":"12AB34"}"#
        report.add(
            input: hashJSON,
            api: "HashColorModel.deserialize(from:).toDictionary()[\"c\"]",
            expected: "#12AB34",
            actual: encodedC(HashColorModel.deserialize(from: hashJSON))
        )
        return report.finish()
    }

    private func userName(_ json: String) -> String {
        guard let model = NameModel.deserialize(from: json) else { return "nil" }
        return model.userName
    }

    private func createdAt(_ json: String) -> String {
        guard let model = DateModel.deserialize(from: json),
              let dictionary = model.toDictionary() else { return "nil" }
        guard let value = dictionary["created_at"] else { return "nil" }
        if let number = value as? NSNumber { return String(number.int64Value) }
        if let number = value as? Int { return String(number) }
        if let number = value as? Int64 { return String(number) }
        return String(describing: value)
    }

    private func colorValue(_ json: String) -> String {
        guard let model = ColorModel.deserialize(from: json),
              let dictionary = model.toDictionary(),
              let text = dictionary["color_value"] as? String else { return "nil" }
        return text
    }

    private func encodedC<T: SmartEncodable>(_ model: T?) -> String {
        guard let text = model?.toDictionary()?["c"] as? String else { return "nil" }
        return text
    }
}

private struct DemoReport {
    private var lines: [String] = []
    private var matched = 0
    private var total = 0
    private let unjudgedPrefix: Int

    init(unjudgedPrefix: Int) {
        self.unjudgedPrefix = unjudgedPrefix
    }

    mutating func add(input: String, api: String, expected: String, actual: String, matches: Bool? = nil) {
        total += 1
        if total <= unjudgedPrefix {
            lines.append("输入: \(input)")
            lines.append("API: \(api)")
            lines.append("期望: 自定义输入未预设期望")
            lines.append("实际: \(actual)")
            lines.append("判定: 未判定")
            lines.append("")
            return
        }
        let same = matches ?? (expected == actual)
        if same { matched += 1 }
        lines.append("输入: \(input)")
        lines.append("API: \(api)")
        lines.append("期望: \(expected)")
        lines.append("实际: \(actual)")
        lines.append("判定: \(same ? "一致" : "不一致")")
        lines.append("")
    }

    func finish() -> [String] {
        let unjudged = min(total, unjudgedPrefix)
        return lines + ["合计: \(total) 项，一致 \(matched) 项，不一致 \(total - unjudged - matched) 项，未判定 \(unjudged) 项"]
    }
}
