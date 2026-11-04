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
        await propertyCheck(count: 150, input: Gen.int(in: 1...100)) { value in
            let result = ArrayHost.deserialize(from: ["values": [value, NSNull(), value + 1]])
            #expect(result?.values == [value, 0, value + 1])
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
