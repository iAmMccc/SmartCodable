import UIKit
import SmartCodable

/// 默认 legacy 保留旧版接受范围；convert 显式启用非可选元素的类型转换。
final class SmartCompactDemoViewController: DemoBaseViewController {
    struct AgesModel: SmartCodableX {
        @SmartCompact.Array var ages: [Int] = []
    }
    struct FlagsModel: SmartCodableX {
        @SmartCompact.Array var flags: [Bool] = []
    }
    struct OptionalScalars: SmartCodableX {
        @SmartCompact.Array var ints: [Int?] = []
        @SmartCompact.Array var strings: [String?] = []
        @SmartCompact.Array var bools: [Bool?] = []
    }
    struct Child: SmartCodableX {
        static var callbacks = 0
        var id: Int = -1
        var calls = 0
        mutating func didFinishMapping() { calls += 1; Self.callbacks += 1 }
    }
    struct KidsModel: SmartCodableX {
        @SmartCompact.Array var kids: [Child] = []
    }
    struct OptionalKidsModel: SmartCodableX {
        @SmartCompact.Array var kids: [Child?] = []
    }

    override var defaultJSON: String { #"{"ages":[1,"2","x",null,4]}"# }

    override func run(with json: String) -> [String] {
        let previous = SmartCodableOptions.compactElementStrategy
        defer { SmartCodableOptions.compactElementStrategy = previous }
        var report = DemoReport(unjudgedPrefix: json == defaultJSON ? 0 : 2)
        for (strategy, name, expected) in modes {
            SmartCodableOptions.compactElementStrategy = strategy
            report.add(input: json, api: "compactElementStrategy = \(name); AgesModel.deserialize.ages",
                       expected: expected, actual: ages(json))
        }
        let flagsJSON = #"{"flags":["yes",1,0,2,"maybe",true]}"#
        let optionalJSON = #"{"ints":[7,"2",null,{},[]],"strings":["ok",7,null,{},[]],"bools":[true,"yes",null,{},[]]}"#
        let kidsJSON = #"{"kids":[{"id":1},null,"bad",{"id":2}]}"#
        for (strategy, name, _) in modes {
            SmartCodableOptions.compactElementStrategy = strategy
            report.add(input: flagsJSON, api: "compactElementStrategy = \(name); FlagsModel.deserialize.flags",
                       expected: strategy == .legacy ? "[true,false,true]" : "[true,true,false,true]",
                       actual: flags(flagsJSON))
            report.add(input: optionalJSON, api: "compactElementStrategy = \(name); OptionalScalars.deserialize",
                       expected: #"ints=[7]; strings=["ok"]; bools=[true]"#, actual: optionals(optionalJSON))
            Child.callbacks = 0
            let optionalKids = OptionalKidsModel.deserialize(from: kidsJSON)
            let optionalActual = optionalKids.map { "count=\($0.kids.count); callbacks=\(Child.callbacks)" } ?? "解码失败"
            report.add(input: kidsJSON, api: "compactElementStrategy = \(name); OptionalKidsModel.deserialize",
                       expected: "count=0; callbacks=0", actual: optionalActual)
            Child.callbacks = 0
            let kids = KidsModel.deserialize(from: kidsJSON)
            let kidsActual = kids.map { "ids=\(formatInts($0.kids.map(\.id))); calls=\(formatInts($0.kids.map(\.calls))); callbacks=\(Child.callbacks)" } ?? "解码失败"
            report.add(input: kidsJSON, api: "compactElementStrategy = \(name); KidsModel.deserialize",
                       expected: "ids=[1,2]; calls=[1,1]; callbacks=2", actual: kidsActual)
        }
        return report.finish()
    }

    private var modes: [(SmartCodableOptions.CompactElementStrategy, String, String)] {
        [(.legacy, ".legacy（默认）", "[1,4]"), (.convert, ".convert（显式）", "[1,2,4]")]
    }
    private func ages(_ json: String) -> String {
        guard let model = AgesModel.deserialize(from: json) else { return "解码失败" }
        return formatInts(model.ages)
    }
    private func flags(_ json: String) -> String {
        guard let model = FlagsModel.deserialize(from: json) else { return "解码失败" }
        return "[" + model.flags.map { $0 ? "true" : "false" }.joined(separator: ",") + "]"
    }
    private func optionals(_ json: String) -> String {
        guard let model = OptionalScalars.deserialize(from: json) else { return "解码失败" }
        let ints = model.ints.map { $0.map(String.init) ?? "null" }.joined(separator: ",")
        let strings = model.strings.map { $0.map { "\"\($0)\"" } ?? "null" }.joined(separator: ",")
        let bools = model.bools.map { $0.map { $0 ? "true" : "false" } ?? "null" }.joined(separator: ",")
        return "ints=[\(ints)]; strings=[\(strings)]; bools=[\(bools)]"
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
