import UIKit
import SmartCodable

/// Demo 7：解码前预处理。
/// 利用 mappingForKey 在解码前重写 key 映射，处理后端"乱起的字段名"。
/// 这是介入解析最前置的方式 —— 让 JSON 看起来"长得对"，再交给 Decoder。
final class PreDecodeStrategyDemoViewController: DemoBaseViewController {

    struct Article: SmartCodableX {
        var title: String = ""
        var author: String = ""
        var publishedAt: String = ""

        static func mappingForKey() -> [SmartKeyTransformer]? {
            [
                // 后端历史包袱：title 字段叫 article_title，作者叫 by，时间叫 ts
                CodingKeys.title       <--- "article_title",
                CodingKeys.author      <--- "by",
                CodingKeys.publishedAt <--- "ts",
            ]
        }
    }

    override var defaultJSON: String {
        """
        {
          "article_title": "SmartCodable 7.0 发布",
          "by": "Mccc",
          "ts": "2026-05-26"
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let model = Article.deserialize(from: json) else {
            return ["解码失败"]
        }
        return [
            "title       = \(model.title)",
            "author      = \(model.author)",
            "publishedAt = \(model.publishedAt)",
            "",
            "📝 mappingForKey 是「解码前」介入的钩子，等同于把字段名提前对齐。",
        ]
    }
}
