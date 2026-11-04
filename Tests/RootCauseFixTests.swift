import Foundation
import XCTest
@testable import SmartCodable

final class RootCauseFixTests: XCTestCase {
    func testOriginalIntegerRangeIsCheckedBeforeRounding() throws {
        struct Model: SmartCodableX { var value: UInt8 = 191 }
        let previous = SmartCodableOptions.numberStrategy
        defer { SmartCodableOptions.numberStrategy = previous }
        for strategy: SmartCodableOptions.NumberConversionStrategy in [.strict, .truncate, .rounded] {
            SmartCodableOptions.numberStrategy = strategy
            for token in ["255.4", "-0.4", "2.554e2", "-4e-1"] {
                XCTAssertEqual(try XCTUnwrap(Model.deserialize(from: ["value": token])).value, 191,
                               "\(strategy)/\(token)")
            }
        }
    }
}
