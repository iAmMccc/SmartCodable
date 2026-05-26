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

    override func run(with json: String) -> [String] {
        cancellables.removeAll()

        guard let counter = Counter.deserialize(from: json) else {
            return ["解码失败"]
        }

        var observed: [String] = []

        // 通过 projectedValue 拿到 Publisher，订阅变化
        counter.$count
            .sink { value in observed.append("count -> \(value)") }
            .store(in: &cancellables)

        counter.$label
            .sink { value in observed.append("label -> \(value)") }
            .store(in: &cancellables)

        // 模拟一次更新
        counter.count += 1
        counter.label = "Updated!"

        var lines: [String] = []
        lines.append("初始解码值：count=\(counter.count - 1) label=\"Hello SwiftUI\"")
        lines.append("")
        lines.append("---- Combine 观察到的事件 ----")
        lines.append(contentsOf: observed)
        lines.append("")
        lines.append("📝 在 SwiftUI 中：")
        lines.append("  @StateObject var counter = Counter.deserialize(from: json) ?? .init()")
        lines.append("  Text(counter.label)  // 自动随发布刷新")
        return lines
    }
}
