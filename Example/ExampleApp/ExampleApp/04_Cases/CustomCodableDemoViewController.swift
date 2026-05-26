import UIKit
import SmartCodable

/// 案例 1：自定义 Codable。
/// 当某个字段不能用普通 mapping 表达（例如 `[String: Int]` 想以数组形式存模型），
/// 可以手写 init(from:) / encode(to:)，并继续保留 SmartCodable 提供的协议能力。
final class CustomCodableDemoViewController: DemoBaseViewController {

    struct ScoreItem: Codable {
        let subject: String
        let score: Int
    }

    /// 模型：JSON 中 scores 是 `{"语文": 95, "数学": 99}`，但模型里更适合用数组持有
    struct Player: SmartCodableX {
        var name: String = ""
        var scores: [ScoreItem] = []

        enum CodingKeys: String, CodingKey {
            case name
            case scores
        }

        init() {}

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = (try? container.decode(String.self, forKey: .name)) ?? ""
            // 把 dict 形式的 scores 转成数组
            if let dict = try? container.decode([String: Int].self, forKey: .scores) {
                self.scores = dict.map { ScoreItem(subject: $0.key, score: $0.value) }
                    .sorted(by: { $0.subject < $1.subject })
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            // 编码时再转回 dict
            let dict = Dictionary(uniqueKeysWithValues: scores.map { ($0.subject, $0.score) })
            try container.encode(dict, forKey: .scores)
        }
    }

    override var defaultJSON: String {
        """
        {
          "name": "Mccc",
          "scores": { "Math": 99, "English": 88, "Science": 95 }
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let player = Player.deserialize(from: json) else {
            return ["解码失败"]
        }
        var lines: [String] = []
        lines.append("---- 解码结果（dict 已转 array）----")
        lines.append("name = \(player.name)")
        for item in player.scores {
            lines.append("  • \(item.subject): \(item.score)")
        }
        lines.append("")
        lines.append("---- 重新编码（array 又回到 dict 形式）----")
        lines.append(player.toJSONString(prettyPrint: true) ?? "")
        return lines
    }
}
