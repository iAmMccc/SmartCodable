import UIKit
import SmartCodable

/// Demo 16：@SmartFlat
/// 把外层多余的"data 容器"扁平化，让模型字段直接对齐内部结构。
final class SmartFlatDemoViewController: DemoBaseViewController {

    // 内层真正的业务结构
    struct Data: SmartCodableX {
        var id: Int = 0
        var title: String = ""
    }

    // 服务端返回 { code, message, data: { id, title } }
    // 我们希望模型直接是 Wrapper { code, message, id, title } —— 用 @SmartFlat 把 data 摊平
    struct Wrapper: SmartCodableX {
        var code: Int = 0
        var message: String = ""
        @SmartFlat var data: Data = Data()
    }

    override var defaultJSON: String {
        """
        {
          "code": 0,
          "message": "ok",
          "id": 99,
          "title": "Hello Flat"
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let wrapper = Wrapper.deserialize(from: json) else {
            return ["解码失败"]
        }
        return [
            "code         = \(wrapper.code)",
            "message      = \(wrapper.message)",
            "data.id      = \(wrapper.data.id)",
            "data.title   = \(wrapper.data.title)",
            "",
            "📝 @SmartFlat 把内层字段「拉平」到外层模型上，常见于网络层壳层处理。",
        ]
    }
}
