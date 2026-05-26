import UIKit
import SmartCodable

/// Demo 1：最基础的解码用法。
final class BasicDecodeDemoViewController: DemoBaseViewController {

    struct User: SmartCodableX {
        var id: Int = 0
        var name: String = ""
        var email: String = ""
    }

    struct Wrapper: SmartCodableX {
        var code: Int = 0
        var data: [User] = []
    }

    override var defaultJSON: String {
        """
        {
          "code": 0,
          "data": [
            { "id": 1, "name": "Mccc", "email": "mccc@example.com" },
            { "id": 2, "name": "Apple", "email": "apple@example.com" }
          ]
        }
        """
    }

    override func run(with json: String) -> [String] {
        var lines: [String] = []

        // 1. 整体解码
        if let wrapper = Wrapper.deserialize(from: json) {
            lines.append("---- 整体解码 Wrapper ----")
            lines.append("code: \(wrapper.code)")
            lines.append("users.count: \(wrapper.data.count)")
            for user in wrapper.data {
                lines.append("  • \(user.id) \(user.name) <\(user.email)>")
            }
        } else {
            lines.append("整体解码失败")
        }

        // 2. designatedPath 直达数组
        lines.append("")
        lines.append("---- 通过 designatedPath = \"data\" 直接解码数组 ----")
        if let users = [User].deserialize(from: json, designatedPath: "data") {
            for user in users {
                lines.append("  • \(user.name)")
            }
        } else {
            lines.append("直达数组失败")
        }

        return lines
    }
}
