import UIKit
import SmartCodable

/// 浮点字符串：非有限值与溢出保持默认值，合法十进制字符串写入 Double / Float。
final class FloatStringDemoViewController: DemoBaseViewController {

    struct Model: SmartCodableX {
        var d: Double = -1
        var f: Float = -1
    }

    override var defaultJSON: String { #"{"d":"3.5"}"# }

    override func run(with json: String) -> [String] {
        var report = DemoReport(unjudgedPrefix: json == defaultJSON ? 0 : 1)
        report.add(
            input: json,
            api: "Model.deserialize(from:).d",
            expected: "3.5",
            actual: doubleField(json, \.d)
        )
        let doubles = [
            (#"{"d":"nan"}"#, "-1"),
            (#"{"d":"inf"}"#, "-1"),
            (#"{"d":"1e400"}"#, "-1"),
            (#"{"d":"1e39"}"#, "1e39"),
        ]
        for (input, expected) in doubles {
            report.add(
                input: input,
                api: "Model.deserialize(from:).d",
                expected: expected,
                actual: doubleField(input, \.d)
            )
        }
        report.add(
            input: #"{"f":"1e39"}"#,
            api: "Model.deserialize(from:).f",
            expected: "-1",
            actual: floatField(#"{"f":"1e39"}"#, \.f)
        )
        return report.finish()
    }

    private func doubleField(_ json: String, _ keyPath: KeyPath<Model, Double>) -> String {
        guard let model = Model.deserialize(from: json) else { return "nil" }
        return formatDouble(model[keyPath: keyPath])
    }

    private func floatField(_ json: String, _ keyPath: KeyPath<Model, Float>) -> String {
        guard let model = Model.deserialize(from: json) else { return "nil" }
        let value = model[keyPath: keyPath]
        if value == -1 { return "-1" }
        return String(value)
    }

    private func formatDouble(_ value: Double) -> String {
        if value == -1 { return "-1" }
        if value == 3.5 { return "3.5" }
        if value == 1e39 { return "1e39" }
        return String(value)
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
