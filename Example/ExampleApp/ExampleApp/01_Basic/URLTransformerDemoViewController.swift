import UIKit
import SmartCodable

/// URL 转换：已经百分号编码的字符串不再二次编码，absoluteString 与输入相同。
final class URLTransformerDemoViewController: DemoBaseViewController {

    private let audited =
        "https://example.com/%E4%B8%AD%E6%96%87/a%20b#frag"

    override var defaultJSON: String { audited }

    override func run(with json: String) -> [String] {
        var report = DemoReport()
        report.add(
            input: json,
            api: "SmartURLTransformer().transformFromJSON(_:).absoluteString",
            expected: audited,
            actual: absoluteString(json)
        )
        let short = "https://a.com/%E4%B8%AD"
        report.add(
            input: short,
            api: "SmartURLTransformer().transformFromJSON(_:).absoluteString",
            expected: short,
            actual: absoluteString(short)
        )
        return report.finish()
    }

    private func absoluteString(_ input: String) -> String {
        SmartURLTransformer().transformFromJSON(input)?.absoluteString ?? "nil"
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
