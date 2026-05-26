import UIKit
import SmartCodable

/// Demo 18：@SmartIgnored
/// 模型上某些字段是"运行时缓存/派生数据"，不应该参与编解码。
final class SmartIgnoredDemoViewController: DemoBaseViewController {

    final class Session: SmartCodableX {
        var token: String = ""
        var expiresIn: Int = 0

        // 不会出现在 JSON 中，也不会被编码出去
        @SmartIgnored var localCachedAt: Date = Date()
        @SmartIgnored var refreshing: Bool = false

        required init() {}
    }

    override var defaultJSON: String {
        """
        {
          "token": "eyJhbGciOi...",
          "expiresIn": 3600,
          "localCachedAt": "should-be-ignored"
        }
        """
    }

    override func run(with json: String) -> [String] {
        guard let session = Session.deserialize(from: json) else {
            return ["解码失败"]
        }
        var lines: [String] = []
        lines.append("token         = \(session.token)")
        lines.append("expiresIn     = \(session.expiresIn)")
        lines.append("localCachedAt = \(session.localCachedAt)  (运行时默认值，未受 JSON 影响)")
        lines.append("refreshing    = \(session.refreshing)")

        lines.append("")
        lines.append("---- 编码（被忽略字段不会出现）----")
        lines.append(session.toJSONString(prettyPrint: true) ?? "")

        return lines
    }
}
