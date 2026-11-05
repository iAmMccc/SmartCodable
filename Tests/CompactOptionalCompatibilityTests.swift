import Foundation
import XCTest
import SmartCodable

final class CompactOptionalCompatibilityTests: XCTestCase {
    private struct Scalars: SmartCodableX {
        @SmartCompact.Array var ints: [Int?] = []
        @SmartCompact.Array var strings: [String?] = []
        @SmartCompact.Array var bools: [Bool?] = []
        @SmartCompact.Array var nested: [Int??] = []
        var ordinary: [Int?] = []
    }

    func testNullFilteringKeepsScalarPositions() throws {
        let m = try XCTUnwrap(Scalars.deserialize(from:
            "{\"ints\":[1,null,2],\"strings\":[\"a\",null,\"b\"],\"bools\":[true,null,false]}"))
        XCTAssertEqual(m.ints, [1, 2])
        XCTAssertEqual(m.strings, ["a", "b"])
        XCTAssertEqual(m.bools, [true, false])
        XCTAssertEqual(m.ints.indices.filter { m.ints[$0] == nil }, [])
    }

    func testInvalidShapesAndConvertibleStringsStayFiltered() throws {
        let m = try XCTUnwrap(Scalars.deserialize(from:
            "{\"ints\":[1,\"2\",\"bad\",null,{},[],1.5,4],\"strings\":[\"a\",{},[],null,\"b\"],\"bools\":[true,{},[],null,false]}"))
        XCTAssertEqual(m.ints, [1, 4])
        XCTAssertEqual(m.strings, ["a", "b"])
        XCTAssertEqual(m.bools, [true, false])
    }

    func testNestedOptionalUsesTheSameRawValueBoundary() throws {
        let m = try XCTUnwrap(Scalars.deserialize(from: "{\"nested\":[1,null,2]}"))
        XCTAssertEqual(m.nested.count, 2)
        XCTAssertEqual(m.nested.map { $0 ?? nil }, [1, 2])
    }

    func testOrdinaryOptionalArrayRetainsNull() throws {
        let m = try XCTUnwrap(Scalars.deserialize(from: "{\"ordinary\":[1,null,2]}"))
        XCTAssertEqual(m.ordinary, [1, nil, 2])
    }

    private static var callbacks = 0
    private struct Child: SmartCodableX {
        var id = 0
        mutating func didFinishMapping() {
            CompactOptionalCompatibilityTests.callbacks += 1
            id += 10
        }
    }
    private struct Children: SmartCodableX {
        @SmartCompact.Array var optional: [Child?] = []
        @SmartCompact.Array var plain: [Child] = []
    }

    func testOptionalModelsStayEmptyAndPlainModelsCompleteOnce() throws {
        Self.callbacks = 0
        let optional = try XCTUnwrap(Children.deserialize(from: "{\"optional\":[{\"id\":1},null,{\"id\":2}]}"))
        XCTAssertTrue(optional.optional.isEmpty)
        XCTAssertEqual(Self.callbacks, 0)
        let plain = try XCTUnwrap(Children.deserialize(from: "{\"plain\":[{\"id\":1},{\"id\":2}]}"))
        XCTAssertEqual(plain.plain.map(\.id), [11, 12])
        XCTAssertEqual(Self.callbacks, 2)
    }
}
