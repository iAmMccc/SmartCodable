import Foundation
import PropertyBased
import SmartCodable
import Testing

private struct ExactInteger: SmartCodableX {
    var value: Int64 = 777_777
}

private struct FirstOwner: SmartCodableX {
    var value: Int = 17
}

private struct SecondOwner: SmartCodableX {
    var value: Int = 91
}

private struct ArrayHost: SmartCodableX {
    var values: [Int] = []
}

private struct ArrayHostWithDeclaredDefault: SmartCodableX {
    var values: [Int] = [7, 7, 7]
}

@Suite(.shrinking)
struct ContractProperties {
    @Test
    func exactDecimalStringWithUnknownKey() async {
        await propertyCheck(count: 200, input: Gen.int(in: -32_768...32_767)) { value in
            let input: [String: Any] = ["value": String(value), "unrelated": ["noise"]]
            let model = ExactInteger.deserialize(from: input)
            #expect(model?.value == Int64(value), "value=\(value)")
        }
    }

    @Test
    func unrelatedKeysDoNotChangeKnownValue() async {
        await propertyCheck(count: 200, input: Gen.int(in: -32_768...32_767)) { value in
            let base = ExactInteger.deserialize(from: ["value": value])
            let noisy = ExactInteger.deserialize(from: ["value": value, "unrelated": ["x": 1]])
            #expect(base?.value == Int64(value))
            #expect(noisy?.value == base?.value)
        }
    }

    @Test
    func objectKeyInsertionOrderDoesNotChangeResult() async {
        await propertyCheck(count: 200, input: Gen.int(in: -32_768...32_767)) { value in
            let unrelatedFirst = "{\"unrelated\":true,\"value\":\(value)}"
            let valueFirst = "{\"value\":\(value),\"unrelated\":true}"
            #expect(ExactInteger.deserialize(from: unrelatedFirst)?.value == Int64(value))
            #expect(ExactInteger.deserialize(from: valueFirst)?.value == Int64(value))
        }
    }

    @Test
    func differentModelOwnersKeepDifferentDefaults() async {
        await propertyCheck(count: 100, input: Gen.int(in: -10...10)) { unrelated in
            let input: [String: Any] = ["unrelated": unrelated]
            #expect(FirstOwner.deserialize(from: input)?.value == 17)
            #expect(SecondOwner.deserialize(from: input)?.value == 91)
        }
    }

    @Test
    func failedArrayElementDoesNotShiftLaterValues() async {
        // 契约：数组元素解析失败时，后续元素不得发生错位。
        // 嵌套属性遵循 7.0.1 基线语义——元素失败会向上传播，整个属性回退到声明的默认值；
        // 根级数组则保留原有位置，失败元素取元素默认值（Int 为 0）。
        await propertyCheck(count: 150, input: Gen.int(in: 1...100)) { value in
            let nativeValues: [Any] = [value, NSNull(), value + 1]

            // 嵌套属性：元素失败 → 整个属性回退到声明的默认值 []。
            let nested = ArrayHost.deserialize(from: ["values": nativeValues])
            #expect(nested?.values == [])

            // 嵌套属性（JSON 字符串输入）：同样回退到声明的默认值 []。
            let nestedJSON = ArrayHost.deserialize(from: "{\"values\":[\(value),null,\(value + 1)]}")
            #expect(nestedJSON?.values == [])

            // 嵌套属性：非 null 的坏元素同样让整个属性回退到声明的默认值。
            let nestedBad = ArrayHost.deserialize(from: ["values": [1, "x", 3] as [Any]])
            #expect(nestedBad?.values == [])

            // 嵌套属性：回退目标是「声明的默认值」本身，而不是空数组。
            let nestedDeclaredDefault = ArrayHostWithDeclaredDefault.deserialize(from: ["values": nativeValues])
            #expect(nestedDeclaredDefault?.values == [7, 7, 7])

            // 根级数组：位置保持不变，失败元素取元素默认值 0，后续元素不位移。
            let rootNative = try? SmartJSONDecoder().smartDecode([Int].self, from: nativeValues)
            #expect(rootNative == [value, 0, value + 1])

            // 根级数组（JSON 字符串输入）：同样保持位置。
            let rootJSON = try? SmartJSONDecoder().smartDecode([Int].self, from: "[\(value),null,\(value + 1)]")
            #expect(rootJSON == [value, 0, value + 1])
        }
    }

    @Test
    func equivalentDataStringAndDictionaryInputsAgree() async {
        await propertyCheck(count: 150, input: Gen.int(in: -10_000...10_000)) { value in
            let json = "{\"value\":\(value)}"
            let stringModel = ExactInteger.deserialize(from: json)
            let dataModel = ExactInteger.deserialize(from: Data(json.utf8))
            let dictionaryModel = ExactInteger.deserialize(from: ["value": value])
            #expect(stringModel?.value == Int64(value))
            #expect(dataModel?.value == stringModel?.value)
            #expect(dictionaryModel?.value == stringModel?.value)
        }
    }

    @Test
    func losslessModelEncodingRoundTrip() async {
        await propertyCheck(count: 120, input: Gen.int(in: -10_000...10_000)) { value in
            let original = ExactInteger(value: Int64(value))
            let decoded = original.toJSONString().flatMap { ExactInteger.deserialize(from: $0) }
            #expect(decoded?.value == Int64(value))
        }
    }
}
