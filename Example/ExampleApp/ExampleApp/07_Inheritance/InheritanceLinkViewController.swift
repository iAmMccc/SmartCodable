import UIKit

/// Demo 21：继承引导页。
/// 自 7.0 起，继承相关能力（@SmartSubclass 宏）已迁移到独立仓库，
/// 让核心库保持轻量、不依赖 swift-syntax。
final class InheritanceLinkViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = .systemFont(ofSize: 15)
        textView.text = """
        🧩 类继承能力（@SmartSubclass）

        从 SmartCodable 7.0 起，类继承相关的宏实现已迁移到独立仓库：

            https://github.com/iAmMccc/SmartCodableMacro

        独立成包的原因：
        • SmartCodableMacro 依赖 swift-syntax，体积大、首次编译耗时长；
        • 不使用继承能力的项目，应该保持轻量；
        • 拆分后两侧版本可独立演进。

        在需要继承的工程中，引入 SmartCodableMacro 即可：
            .package(url: "https://github.com/iAmMccc/SmartCodableMacro.git", from: "1.0.0")
        SmartCodableMacro 会自动依赖 SmartCodable，无需重复声明。

        使用方式：
            class BaseModel: SmartCodableX {
                var name: String = ""
                required init() {}
            }

            @SmartSubclass
            class StudentModel: BaseModel {
                var age: Int = 0
            }

        SmartCodableMacro 仓库内提供了完整的 iOS Demo 工程演示父子类编解码、
        key/value 映射、didFinishMapping 回调等场景。
        """

        view.addSubview(textView)
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -16),
        ])
    }
}
