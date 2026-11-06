import UIKit
import SmartCodable

/// @SmartAny 默认将 Data / Date 编为 null；显式 recursive 才启用动态编码策略。
/// 不可编码的字典值在 @SmartCompact.Dictionary 中被省略。
final class SmartAnyEncodeDemoViewController: DemoBaseViewController {

    struct RuntimeModel: SmartCodableX {
        @SmartAny var ts: Any? = Date(timeIntervalSince1970: 2)
        @SmartAny var data: Any? = Data([1, 2, 3])
    }

    struct Opaque {}

    struct SkipModel: SmartCodableX {
        @SmartCompact.Dictionary var info: [String: Any] = ["bad": Opaque(), "good": 7]
    }

    struct NumberModel: SmartCodableX {
        @SmartAny var v: Any? = nil
    }

    override var defaultJSON: String { #"{"v":1e5}"# }

    override func run(with json: String) -> [String] {
        var report = DemoReport(unjudgedPrefix: 0, unjudgedIndices: json == defaultJSON ? [] : [7])
        for (strategy, name) in [(SmartJSONEncoder.DynamicValueEncodingStrategy.legacy, ".legacy（默认）"), (.recursive, ".recursive（显式）")] {
            let dictionary = runtimeDictionary(strategy)
            report.add(input: "data=Data([1,2,3])", api: "encoder.smartDynamicValueEncodingStrategy = \(name); encode(RuntimeModel()).data",
                       expected: strategy == .legacy ? "null" : "AQID", actual: dictionary.data)
            report.add(input: "ts=Date(timeIntervalSince1970:2)", api: "encoder.smartDynamicValueEncodingStrategy = \(name); encode(RuntimeModel()).ts",
                       expected: strategy == .legacy ? "null" : "-978307198", actual: dictionary.date)
        }
        let skipped = skippedKeys()
        report.add(input: #"{"bad":Opaque(),"good":7}"#, api: "SmartJSONEncoder().encode(SkipModel()).info[\"bad\"]",
                   expected: "键不存在", actual: skipped.bad)
        report.add(input: #"{"bad":Opaque(),"good":7}"#, api: "SmartJSONEncoder().encode(SkipModel()).info[\"good\"]",
                   expected: "7", actual: skipped.good)
        report.add(input: json, api: "NumberModel.deserialize(from:).v.doubleValue", expected: "100000", actual: scientific(json))
        let wideJSON = #"{"v":18446744073709551615}"#
        report.add(input: wideJSON, api: "NumberModel.deserialize(from:).v.stringValue", expected: "18446744073709551615", actual: wide(wideJSON))
        return report.finish()
    }

    private func runtimeDictionary(_ strategy: SmartJSONEncoder.DynamicValueEncodingStrategy) -> (data: String, date: String) {
        let encoder = SmartJSONEncoder()
        encoder.smartDynamicValueEncodingStrategy = strategy
        do {
            let data = try encoder.encode(RuntimeModel())
            guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return ("输出不是字典", "输出不是字典")
            }
            let encodedData: String
            if object["data"] is NSNull { encodedData = "null" }
            else { encodedData = object["data"] as? String ?? "data 缺失或类型错误" }
            let encodedDate: String
            if object["ts"] is NSNull { encodedDate = "null" }
            else { encodedDate = (object["ts"] as? NSNumber)?.stringValue ?? "ts 缺失或类型错误" }
            return (encodedData, encodedDate)
        } catch { return ("编码失败: \(error)", "编码失败: \(error)") }
    }

    private func skippedKeys() -> (bad: String, good: String) {
        guard let data = try? SmartJSONEncoder().encode(SkipModel()),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let info = object["info"] as? [String: Any] else {
            return ("nil", "nil")
        }
        let bad = info["bad"] == nil ? "键不存在" : String(describing: info["bad"]!)
        let good = (info["good"] as? NSNumber).map { String($0.intValue) } ?? "nil"
        return (bad, good)
    }

    private func scientific(_ json: String) -> String {
        guard let number = NumberModel.deserialize(from: json)?.v as? NSNumber else { return "nil" }
        if number.doubleValue == 100000 { return "100000" }
        return String(number.doubleValue)
    }

    private func wide(_ json: String) -> String {
        guard let number = NumberModel.deserialize(from: json)?.v as? NSNumber else { return "nil" }
        return number.stringValue
    }
}

private struct DemoReport {
    private var lines: [String] = []
    private var matched = 0
    private var total = 0
    private let unjudgedPrefix: Int
    private let unjudgedIndices: Set<Int>
    private var unjudgedCount = 0

    init(unjudgedPrefix: Int, unjudgedIndices: Set<Int> = []) {
        self.unjudgedPrefix = unjudgedPrefix
        self.unjudgedIndices = unjudgedIndices
    }

    mutating func add(input: String, api: String, expected: String, actual: String, matches: Bool? = nil) {
        total += 1
        if total <= unjudgedPrefix || unjudgedIndices.contains(total) {
            unjudgedCount += 1
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
        let unjudged = unjudgedCount
        return lines + ["合计: \(total) 项，一致 \(matched) 项，不一致 \(total - unjudged - matched) 项，未判定 \(unjudged) 项"]
    }
}
