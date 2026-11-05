import UIKit
import SmartCodable

/// 数组容错行为。
/// 嵌套数组不再逐位置回退：元素解码失败时错误向上传播，整个属性回退声明默认值。
/// 非可选模型数组 `[Child]` 遇到 null 或非对象元素时，整个属性回退声明默认值（ARR-01）。
/// 逐元素跳过用 `@SmartCompact.Array`。
/// `[Child?]` 里的 null 解码为 nil，并保持原来的位置。
/// 可选模型元素解码成功后仍执行 didFinishMapping（F-09）。
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
        var report = DemoReport()
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
            expected: "[有值, nil, 有值]",
            actual: optionalKids(nullKidsJSON)
        )
        report.add(
            input: nullKidsJSON,
            api: "CallbackKidsModel.deserialize(from:).kids",
            expected: "[11, nil, 12]",
            actual: callbackKids(nullKidsJSON)
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
        let body = model.kids.map { $0 == nil ? "nil" : "有值" }.joined(separator: ", ")
        return "[\(body)]"
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

    mutating func add(input: String, api: String, expected: String, actual: String, matches: Bool? = nil) {
        total += 1
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
        lines + ["合计: \(total) 项，一致 \(matched) 项，不一致 \(total - matched) 项"]
    }
}
