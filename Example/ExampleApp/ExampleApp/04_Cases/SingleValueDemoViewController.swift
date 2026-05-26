import UIKit
import SmartCodable

/// 案例 4：单值容器（singleValueContainer）。
/// 当 JSON 给的是一个裸值（数字、字符串），但模型希望封装成有意义的类型时，
/// 通过 init(from decoder: Decoder) 取 singleValueContainer 完成。
final class SingleValueDemoViewController: DemoBaseViewController {

    /// 模型：服务端给一个分数数字，但 App 想把它封装为「分数 + 等级」
    struct Grade: SmartCodableX {
        var score: Int = 0
        var level: String = "?"

        init() {}

        init(from decoder: Decoder) throws {
            let value = try decoder.singleValueContainer()
            self.score = (try? value.decode(Int.self)) ?? 0
            self.level = Self.levelOf(score: score)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(score)
        }

        static func levelOf(score: Int) -> String {
            switch score {
            case 90...: return "A"
            case 80...: return "B"
            case 60...: return "C"
            default:    return "D"
            }
        }
    }

    struct Report: SmartCodableX {
        var name: String = ""
        var math: Grade = Grade()
        var english: Grade = Grade()
    }

    override var defaultJSON: String {
        """
        {
          "name": "Mccc",
          "math": 95,
          "english": 72
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let report = Report.deserialize(from: json) else {
            return ["解码失败"]
        }
        return [
            "name    = \(report.name)",
            "math    = \(report.math.score) (\(report.math.level))",
            "english = \(report.english.score) (\(report.english.level))",
            "",
            "📝 singleValueContainer 让模型可以从一个「裸值」中读取数据，",
            "再通过 didFinishMapping/计算属性等扩展派生信息。",
        ]
    }
}
