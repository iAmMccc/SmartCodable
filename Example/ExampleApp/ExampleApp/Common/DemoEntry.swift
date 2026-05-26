import UIKit

/// 一个 Demo 的入口描述。
struct DemoEntry {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
}

/// 一个分组。
struct DemoSection {
    let title: String
    let items: [DemoEntry]
}
