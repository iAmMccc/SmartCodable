import UIKit
import SmartCodable

/// 可选字段的 null 在 verbose 下不记日志；非可选 null 与类型不匹配按 debugMode 计数。
final class OptionalNullLogDemoViewController: DemoBaseViewController {

    struct OptionalModel: SmartCodableX {
        var a: Int?
    }

    struct ValueModel: SmartCodableX {
        var b: Int = 0
    }

    override var defaultJSON: String { #"{"a":null}"# }

    override func run(with json: String) -> [String] {
        var report = DemoReport(unjudgedPrefix: json == defaultJSON ? 0 : 1)
        report.add(
            input: json,
            api: "SmartSentinel.debugMode = .verbose; OptionalModel.deserialize(from:)",
            expected: "callbacks=0; main-queue completion barrier=completed",
            actual: count(mode: .verbose) { _ = OptionalModel.deserialize(from: json) }
        )
        report.add(
            input: #"{"a":"abc"}"#,
            api: "SmartSentinel.debugMode = .verbose; OptionalModel.deserialize(from:)",
            expected: "callbacks=1; main-queue completion barrier=completed",
            actual: count(mode: .verbose) { _ = OptionalModel.deserialize(from: #"{"a":"abc"}"#) }
        )
        report.add(
            input: #"{"b":null}"#,
            api: "SmartSentinel.debugMode = .verbose; ValueModel.deserialize(from:)（正向对照）",
            expected: "callbacks=1; main-queue completion barrier=completed",
            actual: count(mode: .verbose) { _ = ValueModel.deserialize(from: #"{"b":null}"#) }
        )
        report.add(
            input: #"{"b":null}"#,
            api: "SmartSentinel.debugMode = .alert; ValueModel.deserialize(from:)",
            expected: "callbacks=0; main-queue completion barrier=completed",
            actual: count(mode: .alert) { _ = ValueModel.deserialize(from: #"{"b":null}"#) }
        )
        report.add(
            input: #"{"b":"abc"}"#,
            api: "SmartSentinel.debugMode = .alert; ValueModel.deserialize(from:)",
            expected: "callbacks=1; main-queue completion barrier=completed",
            actual: count(mode: .alert) { _ = ValueModel.deserialize(from: #"{"b":"abc"}"#) }
        )
        report.add(
            input: #"{"b":"abc"}"#,
            api: "SmartSentinel.debugMode = .none; ValueModel.deserialize(from:)",
            expected: "callbacks=0; main-queue completion barrier=completed",
            actual: count(mode: .none) { _ = ValueModel.deserialize(from: #"{"b":"abc"}"#) }
        )
        return report.finish()
    }

    private func count(mode: SmartSentinel.Level, _ body: () -> Void) -> String {
        let previousMode = SmartSentinel.debugMode
        let recorder = DemoLogRecorder()
        SmartSentinel.debugMode = mode
        SmartSentinel.onLogGenerated { message in
            recorder.record(message)
        }
        defer {
            SmartSentinel.debugMode = previousMode
            SmartSentinel.onLogGenerated { _ in }
        }

        body()
        let barrierCompleted = DemoMainQueueCompletionBarrier.wait(timeout: 1.0)
        let barrierStatus = barrierCompleted ? "completed" : "timeout after 1.0s"
        return "callbacks=\(recorder.messages.count); main-queue completion barrier=\(barrierStatus)"
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
