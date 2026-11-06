import UIKit
import SmartCodable

/// designatedPath 沿用旧行为跳过空段；需要严格路径时由调用方先校验。跨层别名按声明顺序取值。
final class DesignatedPathDemoViewController: DemoBaseViewController {

    struct NameModel: SmartCodableX {
        var name = "dft"
    }

    struct AliasModel: SmartCodableX {
        var name = "dft"

        static func mappingForKey() -> [SmartKeyTransformer]? {
            [CodingKeys.name <--- ["a.b", "alt"]]
        }
    }

    struct DictModel: SmartCodableX {
        var d: [String: Int] = ["z": 0]
    }

    struct FinishChild: SmartCodableX {
        var n: Int = 0

        mutating func didFinishMapping() {
            n += 100
        }
    }

    struct FinishMapModel: SmartCodableX {
        var map: [String: FinishChild] = [:]
    }

    override var defaultJSON: String { #"{"a":{"b":{"name":"x"}},"name":"root"}"# }

    override func run(with json: String) -> [String] {
        var report = DemoReport(unjudgedPrefix: json == defaultJSON ? 0 : 1)
        let canonical = #"{"a":{"b":{"name":"x"}},"name":"root"}"#
        report.add(
            input: json,
            api: "NameModel.deserialize(from: designatedPath: \"a.b\").name",
            expected: "x",
            actual: name(json, path: "a.b")
        )
        let paths = [
            ("", "root"),
            (" ", "root"),
            ("a.", "dft"),
            (".a", "dft"),
            ("a..b", "x"),
            ("missing.name", "nil"),
        ]
        for (path, expected) in paths {
            let shown = path.isEmpty ? "\"\"" : "\"\(path)\""
            report.add(
                input: canonical,
                api: "NameModel.deserialize(from: designatedPath: \(shown)).name",
                expected: expected,
                actual: name(canonical, path: path)
            )
        }
        report.add(
            input: canonical,
            api: "调用方先校验 designatedPath 后再调用 deserialize",
            expected: "nil",
            actual: strictName(canonical, path: "a..b")
        )

        let nullInner = #"{"a":{"b":null},"alt":"X"}"#
        report.add(
            input: nullInner,
            api: "AliasModel.deserialize(from:)，name ← [\"a.b\", \"alt\"]",
            expected: "X",
            actual: alias(nullInner)
        )
        let both = #"{"a":{"b":"Y"},"alt":"X"}"#
        report.add(
            input: both,
            api: "AliasModel.deserialize(from:)，name ← [\"a.b\", \"alt\"]",
            expected: "Y",
            actual: alias(both)
        )

        let dictJSON = #"{"d":"{\"a\":1,\"b\":2}"}"#
        report.add(
            input: dictJSON,
            api: "DictModel.deserialize(from:).d",
            expected: "[\"z\":0]",
            actual: dictionary(dictJSON)
        )
        report.add(
            input: dictJSON,
            api: "JSONSerialization 预处理字典字段后再 deserialize",
            expected: "[\"a\":1,\"b\":2]",
            actual: preprocessedDictionary(dictJSON)
        )
        let arrayJSON = #"{"d":"[1]"}"#
        report.add(
            input: arrayJSON,
            api: "DictModel.deserialize(from:).d",
            expected: "[\"z\":0]",
            actual: dictionary(arrayJSON)
        )

        let finishInput: [String: Any] = [
            "map": [
                "a": ["n": 1],
                "b": ["n": 2],
            ] as [String: Any],
        ]
        let finishResult = finishMap(finishInput)
        report.add(
            input: #"{"map":{"a":{"n":1},"b":{"n":2}}}"#,
            api: "FinishMapModel.deserialize(from:).map",
            expected: "a=1, b=2（字典值默认不触发回调）",
            actual: finishResult,
            matches: finishResult == "a=1, b=2"
        )
        return report.finish()
    }

    private func name(_ json: String, path: String) -> String {
        guard let model = NameModel.deserialize(from: json, designatedPath: path) else { return "nil" }
        return model.name
    }

    private func strictName(_ json: String, path: String) -> String {
        guard path.isEmpty || path.components(separatedBy: ".").allSatisfy({
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else { return "nil" }
        return name(json, path: path)
    }

    private func alias(_ json: String) -> String {
        guard let model = AliasModel.deserialize(from: json) else { return "nil" }
        return model.name
    }

    private func dictionary(_ json: String) -> String {
        guard let model = DictModel.deserialize(from: json) else { return "nil" }
        return dictionary(model)
    }

    private func preprocessedDictionary(_ json: String) -> String {
        guard let input = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any],
              let encodedObject = input["d"] as? String,
              let object = try? JSONSerialization.jsonObject(with: Data(encodedObject.utf8)) as? [String: Any]
        else { return "nil" }
        var preparedInput = input
        preparedInput["d"] = object
        guard let model = DictModel.deserialize(from: preparedInput) else { return "nil" }
        return dictionary(model)
    }

    private func dictionary(_ model: DictModel) -> String {
        let body = model.d.keys.sorted().map { "\"\($0)\":\(model.d[$0]!)" }.joined(separator: ",")
        return "[\(body)]"
    }

    private func finishMap(_ input: [String: Any]) -> String {
        guard let model = FinishMapModel.deserialize(from: input) else { return "nil" }
        let a = model.map["a"].map { String($0.n) } ?? "nil"
        let b = model.map["b"].map { String($0.n) } ?? "nil"
        return "a=\(a), b=\(b)"
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
