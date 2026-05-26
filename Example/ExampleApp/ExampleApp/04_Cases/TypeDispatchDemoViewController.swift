import UIKit
import SmartCodable

/// 案例 5：多态分发。
/// 列表里每条 item 的真实类型由字段 `type` 决定 —— 用枚举 + 关联值统一表达。
/// 通过 SmartAssociatedEnumerable 让枚举本身具备解码能力。
final class TypeDispatchDemoViewController: DemoBaseViewController {

    // 三种内容元素：文本、图片、视频
    struct TextItem: SmartCodableX {
        var content: String = ""
    }

    struct ImageItem: SmartCodableX {
        var url: String = ""
        var width: Int = 0
        var height: Int = 0
    }

    struct VideoItem: SmartCodableX {
        var url: String = ""
        var duration: Int = 0
    }

    enum FeedItem: Codable {
        case text(TextItem)
        case image(ImageItem)
        case video(VideoItem)
        case unknown

        enum CodingKeys: String, CodingKey { case type }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = (try? container.decode(String.self, forKey: .type)) ?? ""
            let raw = try decoder.singleValueContainer()
            switch type {
            case "text":  self = .text((try? raw.decode(TextItem.self)) ?? TextItem())
            case "image": self = .image((try? raw.decode(ImageItem.self)) ?? ImageItem())
            case "video": self = .video((try? raw.decode(VideoItem.self)) ?? VideoItem())
            default:      self = .unknown
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .text(let v):  try container.encode(v)
            case .image(let v): try container.encode(v)
            case .video(let v): try container.encode(v)
            case .unknown:      break
            }
        }
    }

    struct Feed: SmartCodableX {
        var items: [FeedItem] = []
    }

    override var defaultJSON: String {
        """
        {
          "items": [
            { "type": "text",  "content": "Hello SmartCodable" },
            { "type": "image", "url": "https://x/y.png", "width": 1024, "height": 768 },
            { "type": "video", "url": "https://x/z.mp4", "duration": 90 },
            { "type": "live", "url": "??" }
          ]
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let feed = Feed.deserialize(from: json) else {
            return ["解码失败"]
        }
        var lines: [String] = []
        for (i, item) in feed.items.enumerated() {
            switch item {
            case .text(let v):  lines.append("[\(i)] text  -> \(v.content)")
            case .image(let v): lines.append("[\(i)] image -> \(v.url) (\(v.width)x\(v.height))")
            case .video(let v): lines.append("[\(i)] video -> \(v.url) (\(v.duration)s)")
            case .unknown:      lines.append("[\(i)] unknown 类型，已兜底")
            }
        }
        return lines
    }
}
