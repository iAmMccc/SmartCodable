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

    override func run(with json: String) -> [String] {
        // 1. 打开详细日志，回调收集
        SmartSentinel.debugMode = .verbose

        var collected: [String] = []
        let group = DispatchGroup()
        group.enter()

        SmartSentinel.onLogGenerated { message in
            collected.append(message)
            group.leave()
        }

        _ = Person.deserialize(from: json)

        // 等待主队列回调（最多 200ms 不阻塞 UI）
        _ = group.wait(timeout: .now() + 0.2)

        // 关回 none，避免影响其它 demo
        SmartSentinel.debugMode = .none

        var lines: [String] = []
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
