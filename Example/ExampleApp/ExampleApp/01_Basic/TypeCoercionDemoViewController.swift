import UIKit
import SmartCodable

/// Demo 3：类型转换容错。String 与 Number 转换、Number 转 Bool，以及 Bool 转 Int 的默认值回退。
final class TypeCoercionDemoViewController: DemoBaseViewController {

    struct Sample: SmartCodableX {
        var stringFromInt: String = ""    // JSON 给 Int，模型用 String
        var intFromString: Int = 0        // JSON 给 String，模型用 Int
        var boolFromInt: Bool = false     // JSON 给 1/0
        var doubleFromString: Double = 0  // JSON 给 "3.14"
        var intFromBool: Int = 77         // Bool 不转换为整数，保留声明默认值
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

    override var demoAPI: String { "Sample.deserialize" }
    override var expectedOutput: [String] {
        [
            "stringFromInt    = \"12345\"",
            "intFromString    = 678",
            "boolFromInt      = true",
            "doubleFromString = 3.14",
            "intFromBool      = 77",
        ]
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
            "📝 数字可转 Bool；Bool 不转 Int，本例保留默认值 77。",
        ]
    }
}
