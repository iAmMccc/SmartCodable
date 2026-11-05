import UIKit
import SmartCodable

/// 编码映射：顶层标量，以及 key 策略 / 别名与值转换同时生效。
final class EncodeMappingDemoViewController: DemoBaseViewController {

    private struct UpperTransformer: ValueTransformable {
        typealias Object = String
        typealias JSON = String

        func transformFromJSON(_ value: Any) -> String? { (value as? String)?.uppercased() }
        func transformToJSON(_ value: String) -> String? { value.uppercased() }
    }

    private struct TagTransformer: ValueTransformable {
        let tag: String
        typealias Object = Date
        typealias JSON = String

        func transformFromJSON(_ value: Any) -> Date? { nil }
        func transformToJSON(_ value: Date) -> String? { tag }
    }

    struct NameModel: SmartCodableX {
        var userName: String = ""

        static func mappingForValue() -> [SmartValueTransformer]? {
            [CodingKeys.userName <--- UpperTransformer()]
        }
    }

    struct StampModel: SmartCodableX {
        var createdAt: Date = Date(timeIntervalSince1970: 0)
        var expiredAt: Date = Date(timeIntervalSince1970: 1)

        static func mappingForValue() -> [SmartValueTransformer]? {
            [
                CodingKeys.createdAt <--- TagTransformer(tag: "CREATED"),
                CodingKeys.expiredAt <--- TagTransformer(tag: "EXPIRED"),
            ]
        }

        static func mappingForKey() -> [SmartKeyTransformer]? {
            [CodingKeys.expiredAt <--- ["expired_at"]]
        }
    }

    struct FlatUser: SmartCodableX {
        var accid: String = ""
    }

    struct Inner: Encodable {
        enum Keys: String, CodingKey {
            case sub
            case flat
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Keys.self)
            var nested = container.nestedContainer(keyedBy: Keys.self, forKey: .sub)
            try nested.encode(SmartFlat(wrappedValue: FlatUser(accid: "a")), forKey: .flat)
        }
    }

    struct Host: Encodable {
        var inner: Inner = Inner()
    }

    struct Child: SmartCodableX {
        var name: String = ""

        static func mappingForValue() -> [SmartValueTransformer]? {
            [CodingKeys.name <--- UpperTransformer()]
        }
    }

    struct MapModel: SmartCodableX {
        var map: [String: Child] = [:]
        var one: Child?
        var list: [Child?] = []
    }

    override var showsInput: Bool { false }

    override var defaultJSON: String { "42" }

    override func run(with json: String) -> [String] {
        var report = DemoReport()
        report.add(
            input: "42",
            api: "SmartJSONEncoder().encode(42)",
            expected: "42",
            actual: encodeTopLevel(42)
        )
        report.add(
            input: "true",
            api: "SmartJSONEncoder().encode(true)",
            expected: "true",
            actual: encodeTopLevel(true)
        )
        report.add(
            input: "hi",
            api: "SmartJSONEncoder().encode(\"hi\")",
            expected: "\"hi\"",
            actual: encodeTopLevel("hi")
        )

        let snakeEncoder = SmartJSONEncoder()
        snakeEncoder.smartKeyEncodingStrategy = .toSnakeCase
        let snakeActual = encode(NameModel(userName: "mccc"), with: snakeEncoder)
        report.add(
            input: "userName=mccc",
            api: "SmartJSONEncoder().encode(NameModel(userName:))，smartKeyEncodingStrategy = .toSnakeCase",
            expected: "{\"user_name\":\"MCCC\"}",
            actual: snakeActual
        )

        let aliasEncoder = SmartJSONEncoder()
        aliasEncoder.userInfo[.init(rawValue: "Smart.useMappedKeys")!] = true
        let aliasActual = encode(StampModel(), with: aliasEncoder)
        let aliasExpected = "{\"createdAt\":\"CREATED\",\"expired_at\":\"EXPIRED\"}"
        report.add(
            input: "StampModel()",
            api: "SmartJSONEncoder().encode(StampModel())，userInfo Smart.useMappedKeys = true",
            expected: aliasExpected,
            actual: aliasActual,
            matches: sameJSON(aliasActual, aliasExpected)
        )

        let nestedActual = encodeTopLevel(Host())
        let nestedExpected = "{\"inner\":{\"sub\":{\"accid\":\"a\"}}}"
        report.add(
            input: "Host()",
            api: "SmartJSONEncoder().encode(Host())",
            expected: nestedExpected,
            actual: nestedActual,
            matches: sameJSON(nestedActual, nestedExpected)
        )

        let mapped = MapModel(
            map: ["a": Child(name: "x")],
            one: Child(name: "y"),
            list: [Child(name: "z")]
        )
        let mappedActual = encodeTopLevel(mapped)
        let mappedExpected = "包含 \"name\":\"X\"、\"name\":\"Y\"、\"name\":\"Z\""
        report.add(
            input: "map[a]=x, one=y, list=[z]",
            api: "SmartJSONEncoder().encode(MapModel(map:one:list:))",
            expected: mappedExpected,
            actual: mappedActual,
            matches: mappedActual.contains("\"name\":\"X\"")
                && mappedActual.contains("\"name\":\"Y\"")
                && mappedActual.contains("\"name\":\"Z\"")
        )
        return report.finish()
    }

    private func encodeTopLevel<T: Encodable>(_ value: T) -> String {
        encode(value, with: SmartJSONEncoder())
    }

    private func encode<T: Encodable>(_ value: T, with encoder: SmartJSONEncoder) -> String {
        guard let data = try? encoder.encode(value),
              let text = String(data: data, encoding: .utf8) else { return "nil" }
        return text
    }

    /// 比较 JSON 对象时忽略键顺序；实际行仍输出编码器原文。
    private func sameJSON(_ lhs: String, _ rhs: String) -> Bool {
        if lhs == rhs { return true }
        guard
            let leftData = lhs.data(using: .utf8),
            let rightData = rhs.data(using: .utf8),
            let left = try? JSONSerialization.jsonObject(with: leftData),
            let right = try? JSONSerialization.jsonObject(with: rightData)
        else { return false }
        return (left as AnyObject).isEqual(right)
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
