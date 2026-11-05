import UIKit
import SmartCodable

/// SmartUpdater：多别名同时出现时各写各的字段；单别名覆盖；preserving 交还运行时字段。
final class SmartUpdaterDemoViewController: DemoBaseViewController {

    struct SplitModel: SmartCodableX {
        var firstName = "old-first"
        var name = "old-full"

        static func mappingForKey() -> [SmartKeyTransformer]? {
            [CodingKeys.firstName <--- ["first_name", "name"]]
        }
    }

    struct AliasModel: SmartCodableX {
        var name: String = ""

        static func mappingForKey() -> [SmartKeyTransformer]? {
            [CodingKeys.name <--- ["json_name", "alt_name"]]
        }
    }

    struct PreservingModel: SmartCodableX {
        var value: Int = 0
        var local: String = "declared"
        @SmartIgnored var token: String = "declared"

        enum CodingKeys: String, CodingKey {
            case value
        }
    }

    override var defaultJSON: String { #"{"first_name":"Ada","name":"Ada Lovelace"}"# }

    override func run(with json: String) -> [String] {
        var report = DemoReport(unjudgedPrefix: json == defaultJSON ? 0 : 1)
        report.add(
            input: json,
            api: "SmartUpdater.update(&model, from: JSON 对象)",
            expected: "firstName=Ada, name=Ada Lovelace",
            actual: split(json)
        )

        var alias = AliasModel(name: "old")
        SmartUpdater.update(&alias, from: ["alt_name": "new"])
        report.add(
            input: #"{"alt_name":"new"}"#,
            api: "SmartUpdater.update(&model, from: [\"alt_name\": \"new\"])",
            expected: "name=new",
            actual: "name=\(alias.name)"
        )

        var preserving = PreservingModel()
        preserving.local = "runtime-local"
        preserving.token = "runtime-token"
        SmartUpdater.update(&preserving, from: ["value": 2]) { updated, old in
            updated.local = old.local
            updated.token = old.token
        }
        report.add(
            input: #"{"value":2}"#,
            api: "SmartUpdater.update(&model, from: [\"value\": 2], preserving:)",
            expected: "value=2, local=runtime-local, token=runtime-token",
            actual: "value=\(preserving.value), local=\(preserving.local), token=\(preserving.token)"
        )
        return report.finish()
    }

    private func split(_ json: String) -> String {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "nil"
        }
        var model = SplitModel()
        SmartUpdater.update(&model, from: object)
        return "firstName=\(model.firstName), name=\(model.name)"
    }
}

private struct DemoReport {
    private var lines: [String] = []
    private var matched = 0
    private var total = 0
    private let unjudgedPrefix: Int

    init(unjudgedPrefix: Int) {
        self.unjudgedPrefix = unjudgedPrefix
    }

    mutating func add(input: String, api: String, expected: String, actual: String, matches: Bool? = nil) {
        total += 1
        if total <= unjudgedPrefix {
            lines.append("输入: \(input)")
            lines.append("API: \(api)")
            lines.append("期望: 自定义输入未预设期望")
            lines.append("实际: \(actual)")
            lines.append("判定: 未判定")
            lines.append("")
            return
        }
        let same = matches ?? (expected == actual)
        if same { matched += 1 }
        lines.append("输入: \(input)")
        lines.append("API: \(api)")
        lines.append("期望: \(expected)")
        lines.append("实际: \(actual)")
        lines.append("判定: \(same ? "一致" : "不一致")")
        lines.append("")
    }

    func finish() -> [String] {
        let unjudged = min(total, unjudgedPrefix)
        return lines + ["合计: \(total) 项，一致 \(matched) 项，不一致 \(total - unjudged - matched) 项，未判定 \(unjudged) 项"]
    }
}
