import UIKit
import SmartCodable

/// Demo 6：编码。展示 toJSONString / toDictionary / 数组编码。
final class EncodeDemoViewController: DemoBaseViewController {

    struct Address: SmartCodableX {
        var city: String = ""
        var street: String = ""
    }

    struct User: SmartCodableX {
        var id: Int = 0
        var name: String = ""
        var address: Address = Address()
        var tags: [String] = []
    }

    override var defaultJSON: String {
        """
        {
          "id": 1,
          "name": "Mccc",
          "address": { "city": "Suzhou", "street": "Jin Chang" },
          "tags": ["ios", "swift"]
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let user = User.deserialize(from: json) else {
            return ["解码失败"]
        }

        var lines: [String] = []
        lines.append("---- toDictionary ----")
        lines.append("\(user.toDictionary() ?? [:])")

        lines.append("")
        lines.append("---- toJSONString(prettyPrint:) ----")
        lines.append(user.toJSONString(prettyPrint: true) ?? "")

        let users = [user, user]
        lines.append("")
        lines.append("---- 数组编码 ----")
        lines.append(users.toJSONString(prettyPrint: true) ?? "")

        return lines
    }
}
