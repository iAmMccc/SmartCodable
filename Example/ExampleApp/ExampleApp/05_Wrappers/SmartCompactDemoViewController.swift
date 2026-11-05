import UIKit
import SmartCodable

/// @SmartCompact.Array 丢掉无法转换的元素，合法元素保持原有顺序。
final class SmartCompactDemoViewController: DemoBaseViewController {

    struct AgesModel: SmartCodableX {
        @SmartCompact.Array var ages: [Int] = []
    }

    struct FlagsModel: SmartCodableX {
        @SmartCompact.Array var flags: [Bool] = []
    }

    struct Child: SmartCodableX {
        var id: Int = -1
    }

    struct KidsModel: SmartCodableX {
        @SmartCompact.Array var kids: [Child] = []
    }

    override var defaultJSON: String { #"{"ages":[1,"2","x",null,4]}"# }

    override func run(with json: String) -> [String] {
        var report = DemoReport(unjudgedPrefix: json == defaultJSON ? 0 : 1)
        report.add(
            input: json,
            api: "AgesModel.deserialize(from:).ages",
            expected: "[1,2,4]",
            actual: ages(json)
        )
        let flagsJSON = #"{"flags":["yes",1,0,2,"maybe",true]}"#
        report.add(
            input: flagsJSON,
            api: "FlagsModel.deserialize(from:).flags",
            expected: "[true,true,false,true]",
            actual: flags(flagsJSON)
        )
        let kidsJSON = #"{"kids":[{"id":1},null,{"id":2}]}"#
        report.add(
            input: kidsJSON,
            api: "KidsModel.deserialize(from:).kids.map(\\.id)",
            expected: "[1,2]",
            actual: kids(kidsJSON)
        )
        return report.finish()
    }

    private func ages(_ json: String) -> String {
        guard let model = AgesModel.deserialize(from: json) else { return "nil" }
        return formatInts(model.ages)
    }

    private func flags(_ json: String) -> String {
        guard let model = FlagsModel.deserialize(from: json) else { return "nil" }
        let body = model.flags.map { $0 ? "true" : "false" }.joined(separator: ",")
        return "[\(body)]"
    }

    private func kids(_ json: String) -> String {
        guard let model = KidsModel.deserialize(from: json) else { return "nil" }
        return formatInts(model.kids.map(\.id))
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
