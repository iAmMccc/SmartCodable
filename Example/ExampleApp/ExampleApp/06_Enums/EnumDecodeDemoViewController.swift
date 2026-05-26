import UIKit
import SmartCodable

/// Demo 20：枚举解析。
/// 1) SmartCaseDefaultable：原始值枚举（Int/String）—— 后端给非法值时回退到默认 case；
/// 2) SmartAssociatedEnumerable：关联值枚举 —— 通过 mappingForValue + 自定义 transformer 完成。
final class EnumDecodeDemoViewController: DemoBaseViewController {

    // MARK: - 1. RawValue 枚举

    enum Sex: Int, SmartCaseDefaultable {
        case unknown = 0
        case man = 1
        case woman = 2
    }

    enum Role: String, SmartCaseDefaultable {
        case admin
        case user
        case guest
    }

    // MARK: - 2. 关联值枚举

    enum Reward: SmartAssociatedEnumerable {
        case coin(Int)
        case badge(String)
        case none

        static var defaultCase: Reward { .none }
        // 此处仅演示 decode；encode 留空（默认实现返回 nil）。
    }

    struct RewardTransformer: ValueTransformable {
        typealias Object = Reward
        typealias JSON = Any

        func transformFromJSON(_ value: Any) -> Reward? {
            guard let dict = value as? [String: Any], let type = dict["type"] as? String else {
                return .none
            }
            switch type {
            case "coin":
                let v = (dict["value"] as? Int) ?? Int(dict["value"] as? String ?? "") ?? 0
                return .coin(v)
            case "badge":
                return .badge(dict["value"] as? String ?? "")
            default:
                return Reward.defaultCase
            }
        }

        func transformToJSON(_ value: Reward) -> Any? { nil }
    }

    // MARK: - Model

    struct Player: SmartCodableX {
        var name: String = ""
        var sex: Sex = .unknown
        var role: Role = .guest
        var reward: Reward = .none

        static func mappingForValue() -> [SmartValueTransformer]? {
            [CodingKeys.reward <--- RewardTransformer()]
        }
    }

    override var defaultJSON: String {
        """
        {
          "name": "Mccc",
          "sex": 1,
          "role": "admin",
          "reward": { "type": "coin", "value": 9999 }
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let player = Player.deserialize(from: json) else {
            return ["解码失败"]
        }
        var lines: [String] = []
        lines.append("name   = \(player.name)")
        lines.append("sex    = \(player.sex)")
        lines.append("role   = \(player.role)")

        switch player.reward {
        case .coin(let v):  lines.append("reward = .coin(\(v))")
        case .badge(let v): lines.append("reward = .badge(\(v))")
        case .none:         lines.append("reward = .none")
        }

        lines.append("")
        lines.append("📝 SmartCaseDefaultable 适合简单 RawValue 枚举；")
        lines.append("   遇到带关联值的复杂枚举，使用 SmartAssociatedEnumerable + mappingForValue。")
        return lines
    }
}
