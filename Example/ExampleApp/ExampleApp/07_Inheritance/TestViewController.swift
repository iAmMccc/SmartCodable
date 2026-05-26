import UIKit
import SmartCodable

/// 一个空白的测试沙盒页面。
/// 临时验证某段 SmartCodable 行为时，可以直接在这里改代码，无需新建 demo。
final class TestViewController: DemoBaseViewController {

    struct Sample: SmartCodableX {
        var date: Date?
    }

    override var defaultJSON: String {
        """
        {
          "date": "2026-05-26T12:00:00Z"
        }
        """
    }

    override func run(with json: String) -> [String] {
        // 在这里随意修改：测试解码、编码、策略、属性包装器……
        var sample = Sample.deserialize(from: json) ?? Sample()
        sample.date = sample.date ?? Date()

        var lines: [String] = []
        lines.append("---- 解码 ----")
        lines.append("date = \(sample.date.map { "\($0)" } ?? "nil")")
        lines.append("")
        lines.append("---- 编码（默认 ISO8601-like）----")
        lines.append(sample.toJSONString(prettyPrint: true) ?? "")
        lines.append("")
        lines.append("---- 编码（毫秒时间戳）----")
        let dict = sample.toDictionary(options: [.date(.millisecondsSince1970)]) ?? [:]
        lines.append("\(dict)")
        return lines
    }
}
