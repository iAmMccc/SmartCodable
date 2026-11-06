import UIKit
import SmartCodable

/// Demo 10：SmartSentinel 调试日志。
/// 解析过程中遇到「类型不匹配」「key 缺失」「null 值」时，
/// SmartSentinel 会按级别收集并通过 onLogGenerated 回调输出。
final class SmartSentinelDemoViewController: DemoBaseViewController {

    struct Person: SmartCodableX {
        var name: String = ""
        var age: Int = 0
        var address: String = ""
    }

    override var defaultJSON: String {
        """
        {
          "name": 12345,
          "age": "not-a-number",
          "address": null
        }
        """
    }

    override var demoAPI: String { "SmartSentinel.verbose / onLogGenerated; Person.deserialize" }
    override var expectedOutput: [String] {
        [
            "日志回调数 = 1; main-queue completion barrier = completed",
        ]
    }

    override func run(with json: String) -> [String] {
        let previousMode = SmartSentinel.debugMode
        let recorder = DemoLogRecorder()
        SmartSentinel.debugMode = .verbose
        SmartSentinel.onLogGenerated { message in
            recorder.record(message)
        }

        defer {
            SmartSentinel.debugMode = previousMode
            // The public API is setter-only; clear this page's capture after its queued callbacks drain.
            SmartSentinel.onLogGenerated { _ in }
        }

        _ = Person.deserialize(from: json)
        let barrierCompleted = DemoMainQueueCompletionBarrier.wait(timeout: 1.0)
        let collected = recorder.messages
        let barrierStatus = barrierCompleted ? "completed" : "timeout after 1.0s"

        var lines: [String] = []
        lines.append("日志回调数 = \(collected.count); main-queue completion barrier = \(barrierStatus)")
        lines.append("---- SmartSentinel 收集到的日志 ----")
        if collected.isEmpty {
            lines.append("（无日志，可能 JSON 完全合法）")
        } else {
            lines.append(contentsOf: collected)
        }
        lines.append("")
        lines.append("📝 实际开发中：")
        lines.append("- DEBUG 阶段把 SmartSentinel.debugMode 设为 .verbose 或 .alert；")
        lines.append("- onLogGenerated 把日志接到 Crash 上报或自定义日志服务即可定位问题。")
        return lines
    }
}
