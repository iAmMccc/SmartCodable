import XCTest
@testable import SmartCodable

/// 全局配置并发安全测试：验证 SmartCodableOptions 和 SmartSentinel 在多线程并发读写下的稳定性
final class GlobalOptionsConcurrencyTests: XCTestCase {
    override func tearDown() {
        // 每次测试后恢复默认值，防止污染其他测试
        SmartCodableOptions.numberStrategy = .strict
        SmartCodableOptions.ignoreNull = true
        SmartSentinel.debugMode = .none
        super.tearDown()
    }

    /// 200次并发交替读写全局配置和 Sentinel，不崩溃即通过
    func testConcurrentAccessToGlobalOptionsAndSentinel() {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "smartcodable.tests.concurrent", attributes: .concurrent)

        for index in 0..<200 {
            group.enter()
            queue.async {
                switch index % 3 {
                case 0:
                    SmartCodableOptions.numberStrategy = .strict
                case 1:
                    SmartCodableOptions.numberStrategy = .truncate
                default:
                    SmartCodableOptions.numberStrategy = .rounded
                }

                SmartCodableOptions.ignoreNull = index.isMultiple(of: 2)
                SmartSentinel.debugMode = index.isMultiple(of: 2) ? .verbose : .alert

                _ = SmartCodableOptions.numberStrategy
                _ = SmartCodableOptions.ignoreNull
                _ = SmartSentinel.debugMode
                group.leave()
            }
        }

        XCTAssertEqual(group.wait(timeout: .now() + 5), .success)
    }
}
