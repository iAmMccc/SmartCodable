import UIKit
import Combine
import SmartCodable

/// Demo 19：@SmartPublished
/// 在 ObservableObject 模型里，让属性既能被 SmartCodable 解析，又能成为 Combine 的 Publisher，
/// 在 SwiftUI 中天然支持视图刷新。
final class SmartPublishedDemoViewController: DemoBaseViewController {

    final class Counter: ObservableObject, SmartCodableX {
        @SmartPublished var count: Int = 0
        @SmartPublished var label: String = ""
        required init() {}
    }

    override var defaultJSON: String {
        """
        {
          "count": 10,
          "label": "Hello SwiftUI"
        }
        """
    }

    private var cancellables = Set<AnyCancellable>()

    override var demoAPI: String { "Counter.deserialize; $count/$label Combine sink; assignment" }
    override var expectedOutput: [String] {
        [
            "初始解码值：count=10 label=\"Hello SwiftUI\"",
            "count 通知序列 = [10, 11]",
            "label 通知序列 = [\"Hello SwiftUI\", \"Updated!\"]",
            "更新后模型.count = 11",
            "更新后模型.label = \"Updated!\"",
        ]
    }

    override func run(with json: String) -> [String] {
        cancellables.removeAll()

        guard let counter = Counter.deserialize(from: json) else {
            return ["解码失败"]
        }

        var observed: [String] = []
        var countNotifications: [Int] = []
        var labelNotifications: [String] = []

        // 通过 projectedValue 拿到 Publisher，订阅变化
        counter.$count
            .sink { value in
                countNotifications.append(value)
                observed.append("count -> \(value)")
            }
            .store(in: &cancellables)

        counter.$label
            .sink { value in
                labelNotifications.append(value)
                observed.append("label -> \(value)")
            }
            .store(in: &cancellables)

        let initialCount = counter.count
        let initialLabel = counter.label

        // 模拟一次更新
        counter.count += 1
        counter.label = "Updated!"

        var lines: [String] = []
        lines.append("初始解码值：count=\(initialCount) label=\"\(initialLabel)\"")
        lines.append("")
        lines.append("---- Combine 观察到的事件 ----")
        lines.append(contentsOf: observed)
        lines.append("count 通知序列 = [\(countNotifications.map(String.init).joined(separator: ", "))]")
        lines.append("label 通知序列 = [\(labelNotifications.map { "\"\($0)\"" }.joined(separator: ", "))]")
        lines.append("更新后模型.count = \(counter.count)")
        lines.append("更新后模型.label = \"\(counter.label)\"")
        lines.append("")
        lines.append("📝 在 SwiftUI 中：")
        lines.append("  @StateObject var counter = Counter.deserialize(from: json) ?? .init()")
        lines.append("  Text(counter.label)  // 自动随发布刷新")
        return lines
    }
}
