import UIKit
import SmartCodable

/// Demo 5：Value 转换。
/// 通过 mappingForValue 让模型字段在解码时进行自定义转换。
/// 这里演示日期格式化 + 自定义"是/否 -> Bool" 转换。
final class ValueTransformDemoViewController: DemoBaseViewController {

    /// 自定义 Transformer：把 "是" / "否" / 数字 / Bool 都转成 Bool
    struct YesNoTransformer: ValueTransformable {
        typealias Object = Bool
        typealias JSON = Any

        func transformFromJSON(_ value: Any) -> Bool? {
            if let b = value as? Bool { return b }
            if let s = value as? String {
                if s == "是" || s == "yes" || s == "true" || s == "1" { return true }
                if s == "否" || s == "no" || s == "false" || s == "0" { return false }
            }
            if let n = value as? Int { return n != 0 }
            return nil
        }

        func transformToJSON(_ value: Bool) -> Any? {
            value ? "是" : "否"
        }
    }

    struct Person: SmartCodableX {
        var name: String = ""
        var birthday: Date?
        var married: Bool = false

        static func mappingForValue() -> [SmartValueTransformer]? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return [
                CodingKeys.birthday <--- SmartDateTransformer(strategy: .formatted(formatter)),
                CodingKeys.married  <--- YesNoTransformer(),
            ]
        }
    }

    override var defaultJSON: String {
        """
        {
          "name": "Mccc",
          "birthday": "1990-08-15",
          "married": "是"
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let model = Person.deserialize(from: json) else {
            return ["解码失败"]
        }
        return [
            "name     = \(model.name)",
            "birthday = \(model.birthday.map { "\($0)" } ?? "nil")",
            "married  = \(model.married)",
            "",
            "📝 SmartDateTransformer 提供了 .timestamp / .formatted / .iso8601 等内置策略；",
            "也可以像 YesNoTransformer 一样实现 ValueTransformable 协议自定义。",
        ]
    }
}
