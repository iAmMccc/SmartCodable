import UIKit
import SmartCodable

/// Demo 8：解码中的策略。SmartDecodingOption 控制 Date / Data / Float / Key 的解码方式。
/// 这里展示单次调用的日期与 Key 选项；单个字段可用 mappingForValue。
final class InDecodeStrategyDemoViewController: DemoBaseViewController {

    struct Event: SmartCodableX {
        var eventName: String = ""        // 服务端用 snake_case
        var startDate: Date?               // 服务端给毫秒时间戳
    }

    override var defaultJSON: String {
        """
        {
          "event_name": "WWDC 2026",
          "startDate": 1781472000000
        }
        """
    }

    override var demoAPI: String { "Event.deserialize; options: date millisecondsSince1970 / key fromSnakeCase" }
    override var expectedOutput: [String] {
        [
            "eventName = WWDC 2026",
            "毫秒策略秒数 = 1781472000",
        ]
    }

    override func run(with json: String) -> [String] {
        var lines: [String] = []

        // 1. 不带策略：日期由 DateParser 识别输入
        if let model = Event.deserialize(from: json) {
            lines.append("---- 默认策略 ----")
            lines.append("eventName = \(model.eventName)")
            lines.append("startDate  = \(model.startDate.map { "\($0)" } ?? "nil")")
        }

        // 2. 单次调用策略：毫秒时间戳 + 蛇形转驼峰
        let options: Set<SmartDecodingOption> = [
            .date(.millisecondsSince1970),
            .key(.fromSnakeCase),
        ]
        if let model = Event.deserialize(from: json, options: options) {
            lines.append("")
            lines.append("---- 单次策略：millisecondsSince1970 + fromSnakeCase ----")
            lines.append("eventName = \(model.eventName)")
            lines.append("startDate  = \(model.startDate.map { "\($0)" } ?? "nil")")
            lines.append("毫秒策略秒数 = \(model.startDate.map { String(format: "%.0f", $0.timeIntervalSince1970) } ?? "nil")")
        }

        lines.append("")
        lines.append("📝 SmartDecodingOption 提供 .date/.data/.float/.key/.logContext 5 类可传入的策略；")
        lines.append("如需对单个字段单独处理，使用 mappingForValue 局部策略。")
        return lines
    }
}
