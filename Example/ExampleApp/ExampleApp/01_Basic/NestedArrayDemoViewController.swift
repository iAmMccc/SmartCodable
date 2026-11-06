import UIKit
import SmartCodable

/// 数组容错行为。
/// 嵌套数组不再逐位置回退：元素解码失败时错误向上传播，整个属性回退声明默认值。
/// 非可选模型数组 `[Child]` 遇到 null 或非对象元素时，整个属性回退声明默认值（ARR-01）。
/// 逐元素跳过用 `@SmartCompact.Array`。
/// `[Child?]` 里的 null 解码为 nil，并保持原来的位置。
/// [Child?] 元素默认不触发 didFinishMapping；非可选模型数组另有自己的回调路径。
final class NestedArrayDemoViewController: DemoBaseViewController {

    struct MatrixModel: SmartCodableX {
        var m: [[Int]] = [[9]]
    }

    struct ArrayModel: SmartCodableX {
        var a: [Int] = [7]
    }

    struct Child: SmartCodableX {
        var id = -1
    }

    struct KidsModel: SmartCodableX {
        var kids: [Child] = []
    }

    struct CompactKidsModel: SmartCodableX {
        @SmartCompact.Array var kids: [Child] = []
    }

    struct OptionalKidsModel: SmartCodableX {
        var kids: [Child?] = []
    }

    struct CallbackChild: SmartCodableX {
        var id = -1
        mutating func didFinishMapping() { id += 10 }
    }

    struct CallbackKidsModel: SmartCodableX {
        var kids: [CallbackChild?] = []
    }

    override var defaultJSON: String { #"{"m":[[1,2],"x",[3]]}"# }

    override func run(with json: String) -> [String] {
        var report = DemoReport(unjudgedPrefix: json == defaultJSON ? 0 : 1)
        report.add(
            input: json,
            api: "MatrixModel.deserialize(from:).m",
            expected: "[[9]]",
            actual: matrix(json)
        )
        report.add(
            input: #"{"m":[[1,"a"],[3]]}"#,
            api: "MatrixModel.deserialize(from:).m",
            expected: "[[9]]",
            actual: matrix(#"{"m":[[1,"a"],[3]]}"#)
        )
        report.add(
            input: #"{"m":"x"}"#,
            api: "MatrixModel.deserialize(from:).m",
            expected: "[[9]]",
            actual: matrix(#"{"m":"x"}"#)
        )
        report.add(
            input: #"{"a":[1,null,3]}"#,
            api: "ArrayModel.deserialize(from:).a",
            expected: "[7]",
            actual: ints(#"{"a":[1,null,3]}"#)
        )
        report.add(
            input: #"{"kids":[{"id":1},{},{"id":2}]}"#,
            api: "KidsModel.deserialize(from:).kids.map(\\.id)",
            expected: "[1,-1,2]",
            actual: kids(#"{"kids":[{"id":1},{},{"id":2}]}"#)
        )
        let nullKidsJSON = #"{"kids":[{"id":1},null,{"id":2}]}"#
        let nullKids = kids(nullKidsJSON)
        report.add(
            input: nullKidsJSON,
            api: "KidsModel.deserialize(from:).kids.map(\\.id)",
            expected: "[]（ARR-01：null 元素使整个属性回退声明默认值）",
            actual: nullKids,
            matches: nullKids == "[]"
        )
        report.add(
            input: nullKidsJSON,
            api: "CompactKidsModel.deserialize(from:).kids.map(\\.id)",
            expected: "[1,2]",
            actual: compactKids(nullKidsJSON)
        )
        report.add(
            input: nullKidsJSON,
            api: "OptionalKidsModel.deserialize(from:).kids",
            expected: "count=3, ids=[1, nil, 2]",
            actual: optionalKids(nullKidsJSON)
        )
        let callbackResult = callbackKids(nullKidsJSON)
        report.add(
            input: nullKidsJSON,
            api: "CallbackKidsModel.deserialize(from:).kids",
            expected: "[1, nil, 2]（可选元素默认不触发回调）",
            actual: callbackResult,
            matches: callbackResult == "[1, nil, 2]"
        )
        return report.finish()
    }

    private func matrix(_ json: String) -> String {
        guard let model = MatrixModel.deserialize(from: json) else { return "nil" }
        return "[" + model.m.map(formatInts).joined(separator: ",") + "]"
    }

    private func ints(_ json: String) -> String {
        guard let model = ArrayModel.deserialize(from: json) else { return "nil" }
        return formatInts(model.a)
    }

    private func kids(_ json: String) -> String {
        guard let model = KidsModel.deserialize(from: json) else { return "nil" }
        return formatInts(model.kids.map(\.id))
    }

    private func compactKids(_ json: String) -> String {
        guard let model = CompactKidsModel.deserialize(from: json) else { return "nil" }
        return formatInts(model.kids.map(\.id))
    }

    private func optionalKids(_ json: String) -> String {
        guard let model = OptionalKidsModel.deserialize(from: json) else { return "nil" }
        let ids = model.kids.map { child in
            child.map { String($0.id) } ?? "nil"
        }.joined(separator: ", ")
        return "count=\(model.kids.count), ids=[\(ids)]"
    }

    private func callbackKids(_ json: String) -> String {
        guard let model = CallbackKidsModel.deserialize(from: json) else { return "nil" }
        let body = model.kids.map { child in
            child.map { String($0.id) } ?? "nil"
        }.joined(separator: ", ")
        return "[\(body)]"
    }

    private func formatInts(_ values: [Int]) -> String {
        "[" + values.map(String.init).joined(separator: ",") + "]"
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
