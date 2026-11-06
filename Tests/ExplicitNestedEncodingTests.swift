import Foundation
import XCTest
@testable import SmartCodable

private struct ExplicitNestedUpper: ValueTransformable {
    typealias Object = String
    typealias JSON = String

    func transformFromJSON(_ value: Any) -> String? { value as? String }
    func transformToJSON(_ value: String) -> String? { value.uppercased() }
}

private struct ExplicitNestedFlatChild: SmartCodableX {
    var accid = ""
}

private struct ExplicitNestedRow: SmartCodableX {
    var child: SmartFlat<ExplicitNestedFlatChild> = SmartFlat(wrappedValue: ExplicitNestedFlatChild())
    var label = ""
    var tag = ""

    private enum CodingKeys: String, CodingKey {
        case child
        case label
        case tag
    }

    static func mappingForValue() -> [SmartValueTransformer]? {
        [CodingKeys.label <--- ExplicitNestedUpper()]
    }

    init() {}

    init(accid: String, label: String, tag: String) {
        child = SmartFlat(wrappedValue: ExplicitNestedFlatChild(accid: accid))
        self.label = label
        self.tag = tag
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(child, forKey: .child)
        try container.encode(label, forKey: .label)
        try container.encode(tag, forKey: .tag)
    }
}

private struct KeyedToNestedUnkeyedModel: Encodable {
    private enum CodingKeys: String, CodingKey {
        case prefix
        case items
        case sibling
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(17, forKey: .prefix)
        var items = container.nestedUnkeyedContainer(forKey: .items)
        try items.encode(ExplicitNestedRow(accid: "a", label: "row", tag: "first"))
        try container.encode(99, forKey: .sibling)
    }
}

private final class ExplicitNestedEncodingFailureCapture {
    var didThrow = false
    var errorType: String?
    var debugDescription: String?
    var codingPath: [String]?

    func record(_ error: Error) {
        didThrow = true
        guard case EncodingError.invalidValue(_, let context) = error else {
            errorType = String(describing: type(of: error))
            return
        }
        errorType = "EncodingError.invalidValue"
        debugDescription = context.debugDescription
        codingPath = context.codingPath.map(\.stringValue)
    }
}

private struct ExplicitNestedThrowingField: Encodable {
    func encode(to encoder: Encoder) throws {
        throw EncodingError.invalidValue(
            "rejected child",
            .init(codingPath: encoder.codingPath, debugDescription: "explicit nested child failure")
        )
    }
}

private struct UnkeyedToNestedContainerModel: Encodable {
    let capture: ExplicitNestedEncodingFailureCapture

    private enum CodingKeys: String, CodingKey {
        case child
        case value
        case tail
    }

    func encode(to encoder: Encoder) throws {
        var outer = encoder.unkeyedContainer()
        var item = outer.nestedContainer(keyedBy: CodingKeys.self)
        try item.encode(SmartFlat(wrappedValue: ExplicitNestedFlatChild(accid: "a")), forKey: .child)

        do {
            try item.encode(ExplicitNestedThrowingField(), forKey: .value)
        } catch {
            capture.record(error)
        }

        // This field intentionally reuses the failed child's key after the caller catches it.
        try item.encode("recovered", forKey: .value)
        try item.encode(23, forKey: .tail)
        try outer.encode(9)
    }
}

private struct UnkeyedToNestedUnkeyedModel: Encodable {
    func encode(to encoder: Encoder) throws {
        var outer = encoder.unkeyedContainer()
        var inner = outer.nestedUnkeyedContainer()
        try inner.encode(ExplicitNestedRow(accid: "b", label: "inner", tag: "inside"))
        try outer.encode(9)
    }
}

final class ExplicitNestedEncodingTests: XCTestCase {
    func testKeyedToNestedUnkeyedContainerKeepsFlatRowAndHostSibling() throws {
        let actual = try XCTUnwrap(String(data: SmartJSONEncoder().encode(KeyedToNestedUnkeyedModel()), encoding: .utf8))
        let expected = #"{"prefix":17,"items":[{"accid":"a","label":"ROW","tag":"first"}],"sibling":99}"#

        XCTAssertEqual(try ReferenceJSON.parse(actual), try ReferenceJSON.parse(expected), actual)
    }

    func testUnkeyedToNestedContainerRecoversSameNamedFieldAfterThrow() throws {
        let capture = ExplicitNestedEncodingFailureCapture()
        let model = UnkeyedToNestedContainerModel(capture: capture)
        let actual = try XCTUnwrap(String(data: SmartJSONEncoder().encode(model), encoding: .utf8))
        let expected = #"[{"accid":"a","value":"recovered","tail":23},9]"#

        XCTAssertTrue(capture.didThrow, "the nested child failure must reach its caller")
        XCTAssertEqual(capture.errorType, "EncodingError.invalidValue")
        XCTAssertEqual(capture.debugDescription, "explicit nested child failure")
        XCTAssertEqual(capture.codingPath, ["Index 0", "value"])
        XCTAssertEqual(try ReferenceJSON.parse(actual), try ReferenceJSON.parse(expected), actual)
    }

    func testUnkeyedToNestedUnkeyedContainerPreservesInnerAndOuterPositions() throws {
        let actual = try XCTUnwrap(String(data: SmartJSONEncoder().encode(UnkeyedToNestedUnkeyedModel()), encoding: .utf8))
        let expected = #"[[{"accid":"b","label":"INNER","tag":"inside"}],9]"#

        XCTAssertEqual(try ReferenceJSON.parse(actual), try ReferenceJSON.parse(expected), actual)
    }
}
