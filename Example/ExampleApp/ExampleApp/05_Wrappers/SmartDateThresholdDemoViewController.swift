import UIKit
import SmartCodable

/// 毫秒阈值：小于等于 1000000000000 的数字按秒解析，大于该值的数字按毫秒解析。
final class SmartDateThresholdDemoViewController: DemoBaseViewController {

    struct Model: SmartCodableX {
        var date: Date = Date(timeIntervalSince1970: 0)
    }

    override var defaultJSON: String { #"{"date":999999999999}"# }

    override func run(with json: String) -> [String] {
        var report = DemoReport()
        report.add(
            input: json,
            api: "Model.deserialize(from:).date.timeIntervalSince1970",
            expected: "999999999999",
            actual: interval(json)
        )
        let boundary = #"{"date":1000000000000}"#
        report.add(
            input: boundary,
            api: "Model.deserialize(from:).date.timeIntervalSince1970",
            expected: "1000000000000",
            actual: interval(boundary)
        )
        let above = #"{"date":1000000000001}"#
        report.add(
            input: above,
            api: "Model.deserialize(from:).date.timeIntervalSince1970",
            expected: "1000000000.001",
            actual: interval(above)
        )
        return report.finish()
    }

    private func interval(_ json: String) -> String {
        guard let model = Model.deserialize(from: json) else { return "nil" }
        return formatTimestamp(model.date.timeIntervalSince1970)
    }

    private func formatTimestamp(_ value: TimeInterval) -> String {
        let millis = value * 1000
        let rounded = millis.rounded()
        guard abs(millis - rounded) < 0.0001 else { return String(value) }
        let milliInt = Int64(rounded)
        if milliInt % 1000 == 0 {
            return String(milliInt / 1000)
        }
        var text = String(format: "%.3f", Double(milliInt) / 1000)
        while text.last == "0" {
            text.removeLast()
        }
        return text
    }
}

private struct DemoReport {
    private var lines: [String] = []
    private var matched = 0
    private var total = 0

    mutating func add(input: String, api: String, expected: String, actual: String, matches: Bool? = nil) {
        total += 1
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
        lines + ["合计: \(total) 项，一致 \(matched) 项，不一致 \(total - matched) 项"]
    }
}
