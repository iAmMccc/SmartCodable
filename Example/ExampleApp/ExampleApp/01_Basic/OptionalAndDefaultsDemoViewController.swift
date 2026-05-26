import UIKit
import SmartCodable

/// Demo 2：可选与默认值。展示字段缺失、值为 null、类型不匹配时如何兜底。
final class OptionalAndDefaultsDemoViewController: DemoBaseViewController {

    struct Profile: SmartCodableX {
        var id: Int = -1            // 缺失时使用默认值
        var nickname: String = "匿名" // 缺失或 null 时使用默认值
        var age: Int?               // 可选：缺失/null 都是 nil
        var verified: Bool = false  // 缺失时 false
    }

    override var defaultJSON: String {
        """
        {
          "id": 100,
          "nickname": null
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let model = Profile.deserialize(from: json) else {
            return ["解码失败"]
        }
        return [
            "id        = \(model.id)            (默认 -1)",
            "nickname  = \(model.nickname)      (默认 \"匿名\")",
            "age       = \(model.age.map(String.init) ?? "nil")  (可选)",
            "verified  = \(model.verified)      (默认 false)",
            "",
            "📝 SmartCodable 在字段缺失或类型不匹配时，会回退到属性的默认值；",
            "可选字段保持 nil，不会触发解码失败。",
        ]
    }
}
