import Foundation
import SmartCodable
import XCTest

private struct RawInputModel: SmartCodableX {
    var value: Int = 73
}

final class RawInputSmokeTests: XCTestCase {
    /// Bounded syntax/crash smoke only; semantic correctness is checked by
    /// StructuredSemanticTests and NumericContractTests. This is not a fuzzer.
    func testSmallRawByteCorpusDoesNotCrash() throws {
        let decoder = SmartJSONDecoder()
        var attempts = 0
        for byte in UInt8.min...UInt8.max {
            _ = try? decoder.smartDecode(RawInputModel.self, from: Data([byte]))
            _ = try? decoder.smartDecode(RawInputModel.self, from: Data([0x7B, byte, 0x7D]))
            attempts += 2
        }
        XCTAssertEqual(attempts, 512)
        let valid = try decoder.smartDecode(RawInputModel.self,
                                            from: Data(#"{"value":12}"#.utf8))
        XCTAssertEqual(valid.value, 12, "Valid seed must reach the model decoder")
    }
}
