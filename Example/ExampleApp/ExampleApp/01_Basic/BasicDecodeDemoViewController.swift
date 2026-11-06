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

    override var demoAPI: String { "Wrapper.deserialize / [User].deserialize(designatedPath: \"data\")" }
    override var expectedOutput: [String] {
        [
            "code: 0",
            "Wrapper.data.count: 2",
            "Wrapper.data[0]: id=1 name=Mccc email=mccc@example.com",
            "Wrapper.data[1]: id=2 name=Apple email=apple@example.com",
            "designatedPath[0]: id=1 name=Mccc email=mccc@example.com",
            "designatedPath[1]: id=2 name=Apple email=apple@example.com",
            "designatedPath.count: 2",
        ]
    }

    override func run(with json: String) -> [String] {
        var lines: [String] = []

        // 1. 整体解码
        if let wrapper = Wrapper.deserialize(from: json) {
            lines.append("---- 整体解码 Wrapper ----")
            lines.append("code: \(wrapper.code)")
            lines.append("Wrapper.data.count: \(wrapper.data.count)")
            for (index, user) in wrapper.data.enumerated() {
                lines.append("Wrapper.data[\(index)]: \(format(user))")
            }
        } else {
            lines.append("整体解码失败")
        }

        // 2. designatedPath 直达数组
        lines.append("")
        lines.append("---- 通过 designatedPath = \"data\" 直接解码数组 ----")
        if let users = [User].deserialize(from: json, designatedPath: "data") {
            lines.append("designatedPath.count: \(users.count)")
            for (index, user) in users.enumerated() {
                lines.append("designatedPath[\(index)]: \(format(user))")
            }
        } else {
            lines.append("直达数组失败")
        }

        return lines
    }

    private func format(_ user: User) -> String {
        "id=\(user.id) name=\(user.name) email=\(user.email)"
    }
}
