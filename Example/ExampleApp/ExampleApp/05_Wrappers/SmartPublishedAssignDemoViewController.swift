import UIKit
import Combine
import SmartCodable

/// @SmartPublished：宿主使用自定义 objectWillChange 时，赋值仍然写回 wrappedValue。
final class SmartPublishedAssignDemoViewController: DemoBaseViewController {

    final class Host: ObservableObject {
        let objectWillChange = PassthroughSubject<Void, Never>()
        @SmartPublished var score: Int = 7
    }

    override var showsInput: Bool { false }

    override var defaultJSON: String { "42" }

    override func run(with json: String) -> [String] {
        let model = Host()
        model.score = 42
        var report = DemoReport()
        report.add(
            input: "score = 42",
            api: "model.score = 42",
            expected: "42",
            actual: String(model.score)
        )
        return report.finish()
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
