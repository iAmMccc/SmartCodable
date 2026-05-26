import UIKit
import SmartCodable

/// 案例 3：范型解析。
/// 后端通用响应壳 `{ code, message, data: T }`，T 在不同接口里是不同的业务模型。
final class GenericDecodeDemoViewController: DemoBaseViewController {

    struct ApiResponse<T: SmartCodableX>: SmartCodableX {
        var code: Int = 0
        var message: String = ""
        var data: T?
    }

    struct Goods: SmartCodableX {
        var id: Int = 0
        var name: String = ""
        var price: Double = 0
    }

    override var defaultJSON: String {
        """
        {
          "code": 200,
          "message": "ok",
          "data": {
            "id": 1001,
            "name": "iPhone Pro Max",
            "price": 9999
          }
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let resp = ApiResponse<Goods>.deserialize(from: json) else {
            return ["解码失败"]
        }
        var lines: [String] = []
        lines.append("code    = \(resp.code)")
        lines.append("message = \(resp.message)")
        if let data = resp.data {
            lines.append("data:")
            lines.append("  id    = \(data.id)")
            lines.append("  name  = \(data.name)")
            lines.append("  price = \(data.price)")
        } else {
            lines.append("data    = nil")
        }
        lines.append("")
        lines.append("📝 业务层只需写 ApiResponse<某模型>.deserialize 即可获得统一壳层处理。")
        return lines
    }
}
