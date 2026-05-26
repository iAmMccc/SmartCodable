import UIKit
import SmartCodable

/// Demo 8：解码中的策略。SmartDecodingOption 控制 Date / Data / Float / Key 的解码方式。
/// 这里展示日期与 Key 的全局策略 —— 局部覆盖时只需为单个字段写 mappingForValue。
final class InDecodeStrategyDemoViewController: DemoBaseViewController {

    struct Event: SmartCodableX {
        var event_name: String = ""        // 服务端用 snake_case
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

    override func run(with json: String) -> [String] {
        var lines: [String] = []

        // 1. 不带任何策略：日期会按默认 timeIntervalSinceReferenceDate 解析
        if let model = Event.deserialize(from: json) {
            lines.append("---- 默认策略 ----")
            lines.append("event_name = \(model.event_name)")
            lines.append("startDate  = \(model.startDate.map { "\($0)" } ?? "nil")")
        }

        // 2. 全局策略：毫秒时间戳 + 蛇形转驼峰
        let options: Set<SmartDecodingOption> = [
            .date(.millisecondsSince1970),
            .key(.fromSnakeCase),
        ]
        if let model = Event.deserialize(from: json, options: options) {
            lines.append("")
            lines.append("---- 全局策略：millisecondsSince1970 + fromSnakeCase ----")
            lines.append("event_name = \(model.event_name)")
            lines.append("startDate  = \(model.startDate.map { "\($0)" } ?? "nil")")
        }

        lines.append("")
        lines.append("📝 SmartDecodingOption 提供 .date/.data/.float/.key/.logContext 5 类全局策略；")
        lines.append("如需对单个字段单独处理，使用 mappingForValue 局部策略。")
        return lines
    }
}
