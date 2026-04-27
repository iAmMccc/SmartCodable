import XCTest
@testable import SmartCodable

/// 解码边界情况测试：数组索引对齐、类型不匹配、越界回退、数值策略、空值捕获、诊断日志
final class DecodeEdgeCaseTests: XCTestCase {
    override func tearDown() {
        SmartCodableOptions.numberStrategy = .strict
        SmartCodableOptions.ignoreNull = true
        SmartSentinel.debugMode = .none
        SmartSentinel.onLogGenerated { _ in }
        super.tearDown()
    }

    /// 数组解码遇到类型不匹配时，decodeIfPresent 跳过坏值但保持后续索引对齐
    func testDecodeIfPresentStringKeepsArrayIndexAlignedWhenEncounteringMismatchedType() {
        struct Probe: Decodable {
            let first: String?
            let second: String?
            let third: String?

            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                first = try container.decodeIfPresent(String.self)
                second = try container.decodeIfPresent(String.self)
                third = try container.decodeIfPresent(String.self)
            }
        }

        let decoder = SmartJSONDecoder()
        let model = try! decoder.smartDecode(Probe.self, from: [["bad": true], "b", "c"])

        XCTAssertNil(model.first)
        XCTAssertEqual(model.second, "b")
        XCTAssertEqual(model.third, "c")
    }

    /// 正常数组全部解码成功，无数据丢失
    func testDecodeIfPresentStringKeepsAllValidValues() {
        let model = UnkeyedStringArrayModel.deserialize(from: [
            "values": ["a", "b", "c"],
        ])

        XCTAssertEqual(model?.values, ["a", "b", "c"])
    }

    /// 数组越界时回退默认值，不影响后续字段解码
    func testDecodeStringOutOfBoundsFallsBackToDefaultAndKeepsFollowingValueAligned() {
        struct Probe: Decodable {
            let first: String
            let second: String

            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                first = try container.decode(String.self)
                second = try container.decode(String.self)
            }
        }

        let decoder = SmartJSONDecoder()
        let model = try! decoder.smartDecode(Probe.self, from: ["a"])

        XCTAssertEqual(model.first, "a")
        XCTAssertEqual(model.second, "")
    }

    /// truncate 策略：浮点数截断为整数（3.99 → 3）
    func testNumberStrategyTruncateConvertsFloatingPointIntoInteger() {
        SmartCodableOptions.numberStrategy = .truncate

        let model = NumberStrategyModel.deserialize(from: ["value": 3.99])

        XCTAssertEqual(model?.value, 3)
    }

    /// ignoreNull=false 时 @SmartAny 能捕获 NSNull 值
    func testIgnoreNullFalseAllowsSmartAnyToCaptureNSNull() {
        SmartCodableOptions.ignoreNull = false

        let model = SmartAnyNullModel.deserialize(from: ["any": NSNull()])

        XCTAssertTrue(model?.any is NSNull)
    }

    /// SmartSentinel 日志系统：debugMode 切换 + onLogGenerated 回调可用
    func testSmartSentinelDebugModeAndLogHandlerRemainUsable() {
        let expectation = expectation(description: "log handler called")
        SmartSentinel.debugMode = .verbose
        SmartSentinel.onLogGenerated { log in
            if log.contains("Smart Sentinel") {
                expectation.fulfill()
            }
        }

        _ = NumberStrategyModel.deserialize(from: ["value": "oops"])
        wait(for: [expectation], timeout: 1.0)

        SmartSentinel.debugMode = .alert
        XCTAssertEqual(SmartSentinel.debugMode, .alert)
    }
}
