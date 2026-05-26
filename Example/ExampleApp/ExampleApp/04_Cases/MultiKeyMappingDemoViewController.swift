import UIKit
import SmartCodable

/// 案例 2：一字段对应多个候选 JSON key。
/// 后端历史变更频繁时，模型字段可对应多个候选 key，按顺序取第一个非空的值。
final class MultiKeyMappingDemoViewController: DemoBaseViewController {

    struct Account: SmartCodableX {
        var displayName: String = ""
        var avatar: String = ""

        static func mappingForKey() -> [SmartKeyTransformer]? {
            [
                CodingKeys.displayName <--- ["nickName", "realName", "userName"],
                CodingKeys.avatar      <--- ["avatarURL", "headImg", "icon"],
            ]
        }
    }

    override var defaultJSON: String {
        """
        {
          "realName": "Mccc",
          "headImg": "https://example.com/m.png"
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let model = Account.deserialize(from: json) else {
            return ["解码失败"]
        }
        return [
            "displayName = \(model.displayName)",
            "avatar      = \(model.avatar)",
            "",
            "📝 候选 key 数组按顺序匹配，第一个找到非空值的就停止；",
            "对接老接口/灰度兼容两套字段时非常实用。",
        ]
    }
}
