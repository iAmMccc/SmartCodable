import UIKit
import SmartCodable

/// 整数策略：strict 拒绝损失精度，truncate 截断，rounded 四舍五入；超出 Int64 的文本保持默认值。
final class IntegerStrategyDemoViewController: DemoBaseViewController {

    struct Model: SmartCodableX {
        var v: Int = 77
        var w: Int64 = 77
    }

    override var defaultJSON: String { #"{"v":"12.5"}"# }

    override func run(with json: String) -> [String] {
        let previous = SmartCodableOptions.numberStrategy
        defer { SmartCodableOptions.numberStrategy = previous }

        var report = DemoReport(unjudgedPrefix: json == defaultJSON ? 0 : 3)
        addIntCases(json, expected: ["77", "12", "13"], field: "v", into: &report)
        addIntCases(#"{"v":"-12.5"}"#, expected: ["77", "-12", "-13"], field: "v", into: &report)
        addIntCases(#"{"v":"1e2"}"#, expected: ["100", "100", "100"], field: "v", into: &report)
        addIntCases(
            #"{"w":"9223372036854775808"}"#,
            expected: ["77", "77", "77"],
            field: "w",
            into: &report
        )
        return report.finish()
    }

    private func addIntCases(
        _ json: String,
        expected: [String],
        field: String,
        into report: inout DemoReport
    ) {
        let strategies: [(String, SmartCodableOptions.NumberConversionStrategy)] = [
            (".strict", .strict),
            (".truncate", .truncate),
            (".rounded", .rounded),
        ]
        for (index, item) in strategies.enumerated() {
            SmartCodableOptions.numberStrategy = item.1
            let actual: String
            if let model = Model.deserialize(from: json) {
                actual = field == "w" ? String(model.w) : String(model.v)
            } else {
                actual = "nil"
            }
            report.add(
                input: json,
                api: "SmartCodableOptions.numberStrategy = \(item.0); Model.deserialize(from:).\(field)",
                expected: expected[index],
                actual: actual
            )
        }
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
