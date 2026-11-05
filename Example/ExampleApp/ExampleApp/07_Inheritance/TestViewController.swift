import UIKit
import SmartCodable

/// 日期解码和编码的测试沙盒页面。
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

    override var demoAPI: String { "Sample.deserialize; toJSONString / toDictionary(date: millisecondsSince1970)" }
    override var expectedOutput: [String] {
        [
            "ISO8601 日期 = 2026-05-26T12:00:00Z",
            "默认编码参考秒数 = 801489600",
            "毫秒编码值 = 1779796800000",
        ]
    }

    override func run(with json: String) -> [String] {
        // 在这里随意修改：测试解码、编码、策略、属性包装器……
        let sample = Sample.deserialize(from: json) ?? Sample()

        var lines: [String] = []
        lines.append("---- 解码 ----")
        lines.append("date = \(sample.date.map { "\($0)" } ?? "nil")")
        lines.append("")
        lines.append("---- 编码（默认参考日期秒数）----")
        let encodedJSON = sample.toJSONString(prettyPrint: true)
        lines.append(encodedJSON ?? "nil")
        lines.append("")
        lines.append("---- 编码（毫秒时间戳）----")
        let dict = sample.toDictionary(options: [.date(.millisecondsSince1970)]) ?? [:]
        lines.append("\(dict)")
        lines.append("ISO8601 日期 = \(sample.date.map { ISO8601DateFormatter().string(from: $0) } ?? "nil")")
        let defaultValue = (jsonObject(encodedJSON) as? [String: Any])?["date"] as? NSNumber
        let millisecondsValue = dict["date"] as? NSNumber
        lines.append("默认编码参考秒数 = \(defaultValue.map { String(format: "%.17g", $0.doubleValue) } ?? "nil")")
        lines.append("毫秒编码值 = \(millisecondsValue.map { String(format: "%.17g", $0.doubleValue) } ?? "nil")")
        return lines
    }
}
