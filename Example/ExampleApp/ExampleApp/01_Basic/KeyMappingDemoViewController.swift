import UIKit
import SmartCodable

/// Demo 4：Key 映射。
/// - 单 key：将 JSON 中的某个 key 映射到模型字段；
/// - 多 key：当 JSON 可能用不同的 key（如 nickName / realName）时，按顺序取第一个非空的。
final class KeyMappingDemoViewController: DemoBaseViewController {

    struct Student: SmartCodableX {
        var name: String = ""
        var school: String = ""

        static func mappingForKey() -> [SmartKeyTransformer]? {
            [
                // 单 key 映射：JSON.stu_school -> model.school
                CodingKeys.school <--- "stu_school",
                // 多 key 映射：依次尝试 nickName / realName / fullName
                CodingKeys.name <--- ["nickName", "realName", "fullName"],
            ]
        }
    }

    override var defaultJSON: String {
        """
        {
          "realName": "Mccc",
          "stu_school": "Tsinghua"
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let model = Student.deserialize(from: json) else {
            return ["解码失败"]
        }
        return [
            "name   = \(model.name)   (来自 nickName/realName/fullName 任意一个)",
            "school = \(model.school) (来自 stu_school)",
        ]
    }
}
