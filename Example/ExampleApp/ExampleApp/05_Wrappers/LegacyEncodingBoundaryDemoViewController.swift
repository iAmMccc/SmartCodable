import UIKit
import SmartCodable

/// 编码失败边界：使用同一自定义错误，分别核对调用次数、null 回退和错误传播。
final class LegacyEncodingBoundaryDemoViewController: DemoBaseViewController {
    private enum BoundaryError: Error { case expected }
    private final class Trace {
        var events: [String] = []
    }
    private struct PlainValue: Encodable {
        let trace: Trace
        func encode(to encoder: Encoder) throws {
            trace.events.append("encode")
            throw BoundaryError.expected
        }
    }
    private struct SmartValue: SmartCodableX {
        @SmartIgnored var trace: Trace? = nil
        func encode(to encoder: Encoder) throws {
            trace?.events.append("encode")
            throw BoundaryError.expected
        }
    }
    private struct AnyHost: SmartCodableX {
        @SmartAny var value: Any? = nil
    }
    private struct CompactHost: SmartCodableX {
        @SmartCompact.Array var values: [Any] = []
    }

    override var showsInput: Bool { false }

    override func run(with json: String) -> [String] {
        let previous = SmartCodableOptions.compactElementStrategy
        defer { SmartCodableOptions.compactElementStrategy = previous }
        var report = DemoReport(unjudgedPrefix: 0)
        let anyCases: [(Bool, SmartJSONEncoder.DynamicValueEncodingStrategy, String, String)] = [
            (false, .legacy, ".legacy（默认）", #"events=[]; JSON={"value":null}"#),
            (false, .recursive, ".recursive（显式）", "events=[encode]; error=BoundaryError.expected"),
            (true, .legacy, ".legacy（默认）", "events=[encode]; error=BoundaryError.expected"),
        ]
        for (smart, strategy, name, expected) in anyCases {
            let trace = Trace()
            var host = AnyHost()
            host.value = value(smart: smart, trace: trace)
            let encoder = SmartJSONEncoder()
            encoder.smartDynamicValueEncodingStrategy = strategy
            report.add(input: smart ? "SmartCodableX：记录 encode 事件后抛 BoundaryError.expected" : "普通 Encodable：记录 encode 事件后抛 BoundaryError.expected",
                       api: "@SmartAny; encoder.smartDynamicValueEncodingStrategy = \(name); encode(host)",
                       expected: expected, actual: result(trace: trace) { try encoder.encode(host) })
        }
        let compactCases: [(Bool, SmartCodableOptions.CompactElementStrategy, String, String)] = [
            (false, .legacy, ".legacy（默认）", #"events=[]; JSON={"values":[null]}"#),
            (true, .legacy, ".legacy（默认）", #"events=[encode]; JSON={"values":[null]}"#),
            (false, .convert, ".convert（显式）", "events=[encode]; error=BoundaryError.expected"),
            (true, .convert, ".convert（显式）", "events=[encode]; error=BoundaryError.expected"),
        ]
        for (smart, strategy, name, expected) in compactCases {
            SmartCodableOptions.compactElementStrategy = strategy
            let trace = Trace()
            var host = CompactHost()
            host.values = [value(smart: smart, trace: trace)]
            report.add(input: smart ? "[SmartCodableX：记录 encode 后抛 BoundaryError.expected]" : "[普通 Encodable：记录 encode 后抛 BoundaryError.expected]",
                       api: "@SmartCompact.Array; compactElementStrategy = \(name); SmartJSONEncoder().encode(host)",
                       expected: expected, actual: result(trace: trace) { try SmartJSONEncoder().encode(host) })
        }
        return report.finish()
    }

    private func value(smart: Bool, trace: Trace) -> Any {
        if smart {
            var value = SmartValue()
            value.trace = trace
            return value
        }
        return PlainValue(trace: trace)
    }

    private func result(trace: Trace, encode: () throws -> Data) -> String {
        let outcome: String
        do {
            let data = try encode()
            let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            let canonical = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .fragmentsAllowed])
            guard let json = String(data: canonical, encoding: .utf8) else { return "输出不是 UTF-8 JSON" }
            outcome = "JSON=\(json)"
        } catch BoundaryError.expected {
            outcome = "error=BoundaryError.expected"
        } catch {
            outcome = "非预期错误=\(error)"
        }
        return "events=[\(trace.events.joined(separator: ","))]; \(outcome)"
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
