//
//  UnkeyedDecodeIfPresentContractTests.swift
//  SmartCodableTests
//
//  F-02: under `.consumeOnce`, `UnkeyedDecodingContainer.decodeIfPresent` must
//  follow Apple's contract: nil when there is no remaining element, nil when
//  the current element is null. The legacy strategy keeps its behavior.
//  Tests use the public SmartJSONDecoder.smartDecode(_:from:) entry point.
//

import Foundation
import XCTest
@testable import SmartCodable

private final class InitCounter {
    private(set) var count = 0
    func bump() { count += 1 }
}

private extension CodingUserInfoKey {
    static let f02InitCounter = CodingUserInfoKey(rawValue: "SmartCodable.F02.InitCounter")!
}

private struct InputCase {
    let json: String
    let native: [Any]
    var data: Data { Data(json.utf8) }
}

private enum Source: String, CaseIterable {
    case jsonString, data, nativeArray

    func input(for inputCase: InputCase) -> Any {
        switch self {
        case .jsonString: return inputCase.json
        case .data: return inputCase.data
        case .nativeArray: return inputCase.native
        }
    }
}

private enum Cases {
    static let emptyArray = InputCase(json: "[]", native: [])
    static let singleNull = InputCase(json: "[null]", native: [NSNull()])
    static let threeNumbers = InputCase(json: "[1,2,3]", native: [1, 2, 3])
    static let zeroTwoThree = InputCase(json: "[0,2,3]", native: [0, 2, 3])
    static let badSecondThird = InputCase(json: "[\"bad\",\"second\",\"third\"]", native: ["bad", "second", "third"])
    static let nestedEmptyArray = InputCase(json: "[[]]", native: [[Any]()])
}

/// Always fails to decode: isolates the tolerant fallback branch.
private struct AlwaysFailingElement: Decodable {
    init(from decoder: Decoder) throws {
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "always fails"))
    }
}

/// Decodes a positive integer and rejects everything else.
private struct PositiveElement: Decodable {
    let value: Int
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Int.self)
        guard value > 0 else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "positive required"))
        }
        self.value = value
    }
}

/// Tolerates a null value: if `decodeIfPresent` routes null into `init(from:)`,
/// this type would fabricate a non-nil value.
private struct NullTolerantElement: Decodable {
    let value: String
    init(from decoder: Decoder) throws {
        (decoder.userInfo[.f02InitCounter] as? InitCounter)?.bump()
        let container = try decoder.singleValueContainer()
        self.value = (try? container.decode(String.self)) ?? "tolerated-null"
    }
}

/// Always fails to decode but can be recovered through `TypeTransformable`.
private struct ConvertibleElement: Decodable, TypeTransformable {
    let value: String
    init(value: String) { self.value = value }
    init(from decoder: Decoder) throws {
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "always fails"))
    }
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> ConvertibleElement? {
        guard case .string(let text) = value, text != "bad" else { return nil }
        return ConvertibleElement(value: text.uppercased())
    }
}

/// Reads every element through the generic `decodeIfPresent` overload.
private struct SequenceProbe<T: Decodable>: Decodable {
    var values: [T?] = []
    var indices: [Int] = []
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            values.append(try container.decodeIfPresent(T.self))
            indices.append(container.currentIndex)
        }
    }
}

/// Reads the scalar overloads of `decodeIfPresent`.
private struct ScalarProbe: Decodable {
    var returnedNil: [Bool] = []
    var indices: [Int] = []
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        returnedNil.append(try container.decodeIfPresent(Int.self) == nil)
        indices.append(container.currentIndex)
        returnedNil.append(try container.decodeIfPresent(String.self) == nil)
        indices.append(container.currentIndex)
        returnedNil.append(try container.decodeIfPresent(Bool.self) == nil)
        indices.append(container.currentIndex)
        returnedNil.append(try container.decodeIfPresent(Double.self) == nil)
        indices.append(container.currentIndex)
    }
}

/// Calls the generic `decodeIfPresent` past the end of the container.
private struct EndOfContainerProbe: Decodable {
    var returnedNil: [Bool] = []
    var indices: [Int] = []
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        for _ in 0..<3 {
            returnedNil.append(try container.decodeIfPresent(AlwaysFailingElement.self) == nil)
            indices.append(container.currentIndex)
        }
    }
}

/// Mirrors the `Cursor` probe of the root-cause tests: after the loop it calls
/// `decodeIfPresent` past the end and records whether the cursor moved.
private struct CursorEOFProbe: Decodable {
    var values: [Int?] = []
    var indices: [Int] = []
    var eofWasNil = false
    var cursorAfterEOF: Int?
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            values.append(try container.decodeIfPresent(PositiveElement.self)?.value)
            indices.append(container.currentIndex)
        }
        eofWasNil = (try container.decodeIfPresent(PositiveElement.self)) == nil
        cursorAfterEOF = container.currentIndex
    }
}

/// Reads a null element through the generic `decodeIfPresent` overload.
private struct NullProbe: Decodable {
    var values: [String?] = []
    var indices: [Int] = []
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            values.append(try container.decodeIfPresent(NullTolerantElement.self)?.value)
            indices.append(container.currentIndex)
        }
    }
}

/// A nested model that opens its own unkeyed container.
private struct NestedChild: Decodable {
    var returnedNil: [Bool] = []
    var indices: [Int] = []
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        for _ in 0..<2 {
            returnedNil.append(try container.decodeIfPresent(AlwaysFailingElement.self) == nil)
            indices.append(container.currentIndex)
        }
    }
}

/// The nested model is an element of an outer unkeyed container.
private struct NestedHost: Decodable {
    var child: NestedChild?
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.child = try container.decodeIfPresent(NestedChild.self)
    }
}

// MARK: - Tests

final class UnkeyedDecodeIfPresentContractTests: XCTestCase {

    private func makeDecoder(_ strategy: SmartJSONDecoder.UnkeyedDecodingStrategy,
                             counter: InitCounter? = nil) -> SmartJSONDecoder {
        let decoder = SmartJSONDecoder()
        decoder.smartUnkeyedDecodingStrategy = strategy
        if let counter {
            decoder.userInfo[.f02InitCounter] = counter
        }
        return decoder
    }

    private func decodeAcrossSources<T: Decodable>(_ type: T.Type,
                                                   strategy: SmartJSONDecoder.UnkeyedDecodingStrategy,
                                                   input: InputCase) throws -> [(Source, T)] {
        try Source.allCases.map { source in
            (source, try makeDecoder(strategy).smartDecode(type, from: source.input(for: input)))
        }
    }

    private func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ source: Source, _ label: String = "") {
        XCTAssertEqual(actual, expected, "source: \(source.rawValue) \(label)")
    }

    // MARK: - `.consumeOnce`

    /// RED case: at the end of the container `decodeIfPresent` must return nil, not throw.
    func testConsumeOnceDecodeIfPresentAtEndOfContainerReturnsNilWithoutConsuming() throws {
        for source in Source.allCases {
            let decoder = makeDecoder(.consumeOnce)
            var probe: EndOfContainerProbe?
            XCTAssertNoThrow(probe = try decoder.smartDecode(EndOfContainerProbe.self,
                                                            from: source.input(for: Cases.emptyArray)),
                             "source: \(source.rawValue): decodeIfPresent must return nil at end of container, not throw")
            assertEqual(probe?.returnedNil ?? [], [true, true, true], source, "repeated EOF calls")
            assertEqual(probe?.indices ?? [], [0, 0, 0], source, "cursor must not advance past the end")
        }
    }

    /// The scalar overloads must behave the same at the end of the container.
    func testConsumeOnceScalarDecodeIfPresentAtEndOfContainerKeepsCursor() throws {
        for (source, probe) in try decodeAcrossSources(ScalarProbe.self, strategy: .consumeOnce, input: Cases.emptyArray) {
            assertEqual(probe.returnedNil, [true, true, true, true], source)
            assertEqual(probe.indices, [0, 0, 0, 0], source)
        }
    }

    /// A null element returns nil, is consumed once, and never reaches a null-tolerant `init(from:)`.
    func testConsumeOnceDecodeIfPresentReturnsNilForNullElementWithoutInvokingCustomInit() throws {
        for source in Source.allCases {
            let counter = InitCounter()
            let probe = try makeDecoder(.consumeOnce, counter: counter)
                .smartDecode(NullProbe.self, from: source.input(for: Cases.singleNull))
            assertEqual(probe.values, [nil], source)
            assertEqual(probe.indices, [1], source, "the null element is consumed exactly once")
            assertEqual(counter.count, 0, source, "a null-tolerant init(from:) must not be invoked")
        }
    }

    /// A successful decode consumes exactly one element.
    func testConsumeOnceDecodeIfPresentConsumesSuccessfulValueExactlyOnce() throws {
        for (source, probe) in try decodeAcrossSources(SequenceProbe<Int>.self, strategy: .consumeOnce, input: Cases.threeNumbers) {
            assertEqual(probe.values, [1, 2, 3], source)
            assertEqual(probe.indices, [1, 2, 3], source)
        }
    }

    /// A failed decode falls back to nil, consumes one element, skips nothing.
    func testConsumeOnceDecodeIfPresentFailedFallbackConsumesExactlyOneElement() throws {
        for (source, probe) in try decodeAcrossSources(SequenceProbe<PositiveElement>.self, strategy: .consumeOnce, input: Cases.zeroTwoThree) {
            assertEqual(probe.values.map { $0?.value }, [nil, 2, 3], source)
            assertEqual(probe.indices, [1, 2, 3], source, "the next valid element must not be skipped")
        }
    }

    /// A successful conversion fallback consumes one element, skips nothing.
    func testConsumeOnceDecodeIfPresentConversionFallbackConsumesExactlyOneElement() throws {
        for (source, probe) in try decodeAcrossSources(SequenceProbe<ConvertibleElement>.self, strategy: .consumeOnce, input: Cases.badSecondThird) {
            assertEqual(probe.values.map { $0?.value }, [nil, "SECOND", "THIRD"], source)
            assertEqual(probe.indices, [1, 2, 3], source, "the next valid element must not be skipped")
        }
    }

    /// The strategy propagates into a model nested inside the unkeyed container.
    func testConsumeOnceStrategyPropagatesIntoNestedUnkeyedContainer() throws {
        for (source, host) in try decodeAcrossSources(NestedHost.self, strategy: .consumeOnce, input: Cases.nestedEmptyArray) {
            XCTAssertNotNil(host.child, "source: \(source.rawValue)")
            assertEqual(host.child?.returnedNil ?? [], [true, true], source)
            assertEqual(host.child?.indices ?? [], [0, 0], source)
        }
    }

    /// The root-cause `Cursor` shape: at the end `decodeIfPresent` returns nil and the cursor stays.
    func testConsumeOnceEndOfContainerAssertionHoldsForRootCauseCursorShape() throws {
        for (source, probe) in try decodeAcrossSources(CursorEOFProbe.self, strategy: .consumeOnce, input: Cases.zeroTwoThree) {
            assertEqual(probe.values, [nil, 2, 3], source)
            assertEqual(probe.indices, [1, 2, 3], source)
            XCTAssertTrue(probe.eofWasNil, "source: \(source.rawValue): XCTAssertNil at end of container must hold")
            assertEqual(probe.cursorAfterEOF, probe.indices.last, source, "the cursor must not advance at the end")
        }
    }

    // MARK: - `.legacy` (historical behavior must not change)

    /// The legacy generic fallback keeps its historical double consumption.
    func testLegacyGenericFallbackKeepsHistoricalDoubleConsumption() throws {
        for (source, probe) in try decodeAcrossSources(SequenceProbe<PositiveElement>.self, strategy: .legacy, input: Cases.zeroTwoThree) {
            assertEqual(probe.values.map { $0?.value }, [nil, 3], source)
            assertEqual(probe.indices, [2, 3], source)
        }
    }

    /// The legacy generic overload keeps advancing the cursor past the end.
    func testLegacyGenericDecodeIfPresentAtEndOfContainerKeepsHistoricalCursor() throws {
        for (source, probe) in try decodeAcrossSources(EndOfContainerProbe.self, strategy: .legacy, input: Cases.emptyArray) {
            assertEqual(probe.returnedNil, [true, true, true], source)
            assertEqual(probe.indices, [2, 4, 6], source)
        }
    }

    /// The legacy scalar overloads keep advancing the cursor past the end.
    func testLegacyScalarDecodeIfPresentAtEndOfContainerKeepsHistoricalCursor() throws {
        for (source, probe) in try decodeAcrossSources(ScalarProbe.self, strategy: .legacy, input: Cases.emptyArray) {
            assertEqual(probe.returnedNil, [true, true, true, true], source)
            assertEqual(probe.indices, [1, 2, 3, 4], source)
        }
    }

    /// The legacy strategy still routes a null element into `init(from:)`.
    func testLegacyNullElementStillInvokesCustomInit() throws {
        for source in Source.allCases {
            let counter = InitCounter()
            let probe = try makeDecoder(.legacy, counter: counter)
                .smartDecode(NullProbe.self, from: source.input(for: Cases.singleNull))
            assertEqual(probe.values, ["tolerated-null"], source)
            assertEqual(probe.indices, [1], source)
            assertEqual(counter.count, 1, source)
        }
    }

    /// The legacy strategy keeps decoding every element of a valid array.
    func testLegacySuccessfulValuesAreUnchanged() throws {
        for (source, probe) in try decodeAcrossSources(SequenceProbe<Int>.self, strategy: .legacy, input: Cases.threeNumbers) {
            assertEqual(probe.values, [1, 2, 3], source)
            assertEqual(probe.indices, [1, 2, 3], source)
        }
    }

    /// The legacy strategy keeps its historical cursor drift at the end.
    func testLegacyEndOfContainerCursorStillDrifts() throws {
        for (source, probe) in try decodeAcrossSources(CursorEOFProbe.self, strategy: .legacy, input: Cases.zeroTwoThree) {
            XCTAssertTrue(probe.eofWasNil, "source: \(source.rawValue)")
            assertEqual(probe.cursorAfterEOF, (probe.indices.last ?? 0) + 2, source)
        }
    }
}
