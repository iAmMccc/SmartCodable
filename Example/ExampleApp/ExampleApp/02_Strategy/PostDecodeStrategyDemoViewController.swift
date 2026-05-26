import UIKit
import SmartCodable

/// Demo 9：解码后回调。
/// `didFinishMapping()` 在所有字段解码完成后触发，用来做：
/// - 字段间的派生计算（如 fullName = firstName + lastName）
/// - 业务校验/兜底
/// - 进一步规范化
final class PostDecodeStrategyDemoViewController: DemoBaseViewController {

    final class Order: SmartCodableX {
        var firstName: String = ""
        var lastName: String = ""
        var price: Double = 0
        var discount: Double = 0

        // 解码完成后自动派生的字段
        var fullName: String = ""
        var finalPrice: Double = 0

        required init() {}

        func didFinishMapping() {
            fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            // 兜底：折扣超出 0~1 视为无效
            let normalizedDiscount = (0...1).contains(discount) ? discount : 0
            finalPrice = price * (1 - normalizedDiscount)
        }
    }

    override var defaultJSON: String {
        """
        {
          "firstName": "Qi",
          "lastName": "Xin",
          "price": 99.0,
          "discount": 0.2
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let order = Order.deserialize(from: json) else {
            return ["解码失败"]
        }
        return [
            "firstName  = \(order.firstName)",
            "lastName   = \(order.lastName)",
            "price      = \(order.price)",
            "discount   = \(order.discount)",
            "—— didFinishMapping 派生 ——",
            "fullName   = \(order.fullName)",
            "finalPrice = \(order.finalPrice)",
            "",
            "📝 didFinishMapping 是模型的「收尾仪式」，可以放心读其它已解码字段。",
        ]
    }
}
