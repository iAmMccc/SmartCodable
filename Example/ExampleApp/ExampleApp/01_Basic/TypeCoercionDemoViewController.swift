import UIKit
import SmartCodable

/// Demo 3：类型转换容错。String / Number / Bool 之间常见的互转。
final class TypeCoercionDemoViewController: DemoBaseViewController {

    struct Sample: SmartCodableX {
        var stringFromInt: String = ""    // JSON 给 Int，模型用 String
        var intFromString: Int = 0        // JSON 给 String，模型用 Int
        var boolFromInt: Bool = false     // JSON 给 1/0
        var doubleFromString: Double = 0  // JSON 给 "3.14"
        var intFromBool: Int = 0          // JSON 给 true/false
    }

    override var defaultJSON: String {
        """
        {
          "stringFromInt": 12345,
          "intFromString": "678",
          "boolFromInt": 1,
          "doubleFromString": "3.14",
          "intFromBool": true
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let model = Sample.deserialize(from: json) else {
            return ["解码失败"]
        }
        return [
            "stringFromInt    = \"\(model.stringFromInt)\"",
            "intFromString    = \(model.intFromString)",
            "boolFromInt      = \(model.boolFromInt)",
            "doubleFromString = \(model.doubleFromString)",
            "intFromBool      = \(model.intFromBool)",
            "",
            "📝 SmartCodable 内置常见基础类型互转，写后端时不必再为「字符串数字」头疼。",
        ]
    }
}
