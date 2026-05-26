import UIKit

/// Demo 通用基类：上方显示输入 JSON，中间「运行」按钮，下方显示输出结果。
/// 子类只需要重写 `defaultJSON` 与 `run(with:)` 即可。
class DemoBaseViewController: UIViewController {

    // MARK: - 子类需重写

    /// 默认 JSON 文本。子类可重写为自己的演示用例。
    var defaultJSON: String { "{}" }

    /// 子类实现：根据输入文本运行 demo，返回要展示的多行结果。
    func run(with json: String) -> [String] {
        ["子类未实现 run(with:)"]
    }

    /// 子类可重写：是否需要显示输入框（部分 demo 不需要 JSON 输入）。
    var showsInput: Bool { true }

    // MARK: - UI

    let inputTextView = UITextView()
    let outputTextView = UITextView()
    private let runButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        runDemo()
    }

    private func setupUI() {
        let outputLabel = makeSectionLabel("运行结果")

        outputTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        outputTextView.layer.borderColor = UIColor.separator.cgColor
        outputTextView.layer.borderWidth = 1
        outputTextView.layer.cornerRadius = 6
        outputTextView.isEditable = false

        runButton.setTitle("运行", for: .normal)
        runButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        runButton.addTarget(self, action: #selector(runDemo), for: .touchUpInside)

        let safe = view.safeAreaLayoutGuide

        if showsInput {
            let inputLabel = makeSectionLabel("输入 JSON（点击「运行」可重新解码）")
            inputTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
            inputTextView.layer.borderColor = UIColor.separator.cgColor
            inputTextView.layer.borderWidth = 1
            inputTextView.layer.cornerRadius = 6
            inputTextView.text = defaultJSON
            inputTextView.autocapitalizationType = .none
            inputTextView.autocorrectionType = .no

            [inputLabel, inputTextView, runButton, outputLabel, outputTextView].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview($0)
            }

            NSLayoutConstraint.activate([
                inputLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 12),
                inputLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
                inputLabel.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),

                inputTextView.topAnchor.constraint(equalTo: inputLabel.bottomAnchor, constant: 6),
                inputTextView.leadingAnchor.constraint(equalTo: inputLabel.leadingAnchor),
                inputTextView.trailingAnchor.constraint(equalTo: inputLabel.trailingAnchor),
                inputTextView.heightAnchor.constraint(equalToConstant: 180),

                runButton.topAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: 8),
                runButton.centerXAnchor.constraint(equalTo: safe.centerXAnchor),

                outputLabel.topAnchor.constraint(equalTo: runButton.bottomAnchor, constant: 12),
                outputLabel.leadingAnchor.constraint(equalTo: inputLabel.leadingAnchor),
                outputLabel.trailingAnchor.constraint(equalTo: inputLabel.trailingAnchor),

                outputTextView.topAnchor.constraint(equalTo: outputLabel.bottomAnchor, constant: 6),
                outputTextView.leadingAnchor.constraint(equalTo: inputLabel.leadingAnchor),
                outputTextView.trailingAnchor.constraint(equalTo: inputLabel.trailingAnchor),
                outputTextView.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -16),
            ])
        } else {
            [runButton, outputLabel, outputTextView].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview($0)
            }
            NSLayoutConstraint.activate([
                runButton.topAnchor.constraint(equalTo: safe.topAnchor, constant: 16),
                runButton.centerXAnchor.constraint(equalTo: safe.centerXAnchor),

                outputLabel.topAnchor.constraint(equalTo: runButton.bottomAnchor, constant: 12),
                outputLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
                outputLabel.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),

                outputTextView.topAnchor.constraint(equalTo: outputLabel.bottomAnchor, constant: 6),
                outputTextView.leadingAnchor.constraint(equalTo: outputLabel.leadingAnchor),
                outputTextView.trailingAnchor.constraint(equalTo: outputLabel.trailingAnchor),
                outputTextView.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -16),
            ])
        }
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }

    @objc private func runDemo() {
        let json = showsInput ? inputTextView.text ?? "" : ""
        let lines = run(with: json)
        outputTextView.text = lines.joined(separator: "\n")
    }
}
