import UIKit
import SmartCodable

/// @SmartAny 把运行时的 Data / Date 编进字典，并保留科学计数法与超大整数。
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
        var report = DemoReport()
        let dictionary = RuntimeModel().toDictionary()
        report.add(
            input: "ts=Date(timeIntervalSince1970: 2), data=Data([1, 2, 3])",
            api: "Model().toDictionary()[\"data\"]",
            expected: "AQID",
            actual: encodedData(dictionary)
        )
        report.add(
            input: "ts=Date(timeIntervalSince1970: 2), data=Data([1, 2, 3])",
            api: "Model().toDictionary()[\"ts\"].doubleValue",
            expected: "-978307198",
            actual: encodedTimestamp(dictionary)
        )

        let skipped = skippedKeys()
        report.add(
            input: #"{"bad":Opaque(),"good":7}"#,
            api: "SmartJSONEncoder().encode(SkipModel()).info[\"bad\"]",
            expected: "键不存在",
            actual: skipped.bad,
            matches: skipped.bad == "键不存在"
        )
        report.add(
            input: #"{"bad":Opaque(),"good":7}"#,
            api: "SmartJSONEncoder().encode(SkipModel()).info[\"good\"]",
            expected: "7",
            actual: skipped.good
        )

        report.add(
            input: json,
            api: "NumberModel.deserialize(from:).v.doubleValue",
            expected: "100000",
            actual: scientific(json)
        )
        let wideJSON = #"{"v":18446744073709551615}"#
        report.add(
            input: wideJSON,
            api: "NumberModel.deserialize(from:).v.stringValue",
            expected: "18446744073709551615",
            actual: wide(wideJSON)
        )
        return report.finish()
    }

    private func encodedData(_ dictionary: [String: Any]?) -> String {
        guard let text = dictionary?["data"] as? String else { return "nil" }
        return text
    }

    private func encodedTimestamp(_ dictionary: [String: Any]?) -> String {
        guard let number = dictionary?["ts"] as? NSNumber else { return "nil" }
        if number.doubleValue == -978307198 { return "-978307198" }
        return String(number.doubleValue)
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
