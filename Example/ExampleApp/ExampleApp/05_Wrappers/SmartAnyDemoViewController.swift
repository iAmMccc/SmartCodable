import UIKit
import SmartCodable

/// Demo 17：@SmartAny
/// 当 JSON 字段类型在编译期不可知（接口返回灵活），用 @SmartAny 让模型仍可解析与编码。
final class SmartAnyDemoViewController: DemoBaseViewController {

    struct Box: SmartCodableX {
        @SmartAny var dynamic: Any?            // 任意单值
        @SmartAny var info: [String: Any] = [:] // 动态字典
        @SmartAny var tags: [Any] = []          // 异构数组
    }

    override var defaultJSON: String {
        """
        {
          "dynamic": 3.14,
          "info": {
            "title": "SmartAny",
            "count": 42,
            "ratio": 0.85,
            "ok": true
          },
          "tags": ["ios", 7, true, { "kind": "swift" }]
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let box = Box.deserialize(from: json) else {
            return ["解码失败"]
        }
        var lines: [String] = []
        lines.append("dynamic = \(box.dynamic ?? "nil")")
        lines.append("info    = \(box.info)")
        lines.append("tags    = \(box.tags)")

        lines.append("")
        lines.append("---- 编码回 JSON ----")
        lines.append(box.toJSONString(prettyPrint: true) ?? "")

        lines.append("")
        lines.append("📝 @SmartAny 内部把异构值规范化存储，编解码时保持原结构。")
        return lines
    }
}
