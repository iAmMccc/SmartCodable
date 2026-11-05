import XCTest
@testable import SmartCodable

/// 全局配置并发测试。普通运行验证任务完成且无死锁；数据竞争必须配合 Thread Sanitizer 检测：
/// `swift test --sanitize=thread --filter GlobalOptionsConcurrencyTests`
final class GlobalOptionsConcurrencyTests: XCTestCase {
    override func tearDown() {
        // 每次测试后恢复默认值，防止污染其他测试
        SmartCodableOptions.numberStrategy = .strict
        SmartCodableOptions.ignoreNull = true
        SmartCodableOptions.compactElementStrategy = .legacy
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
                SmartCodableOptions.compactElementStrategy = index.isMultiple(of: 2) ? .legacy : .convert
                SmartSentinel.debugMode = index.isMultiple(of: 2) ? .verbose : .alert

                _ = SmartCodableOptions.numberStrategy
                _ = SmartCodableOptions.ignoreNull
                _ = SmartCodableOptions.compactElementStrategy
                _ = SmartSentinel.debugMode
                group.leave()
            }
        }

        XCTAssertEqual(group.wait(timeout: .now() + 5), .success)
    }

    /// 多线程同时解码并产生日志：LogCache 必须整体线程安全。
    /// 数据竞争由 Thread Sanitizer 检测：
    /// `swift test --sanitize=thread --filter GlobalOptionsConcurrencyTests`
    func testConcurrentDecodingWithLogs() {
        defer {
            SmartSentinel.debugMode = .none
            SmartSentinel.onLogGenerated { _ in }
        }

        SmartSentinel.debugMode = .alert

        let lock = NSLock()
        var values: [Int?] = []
        var messages: [String] = []
        let logs = expectation(description: "one log per decode")
        logs.expectedFulfillmentCount = 200

        SmartSentinel.onLogGenerated { message in
            lock.lock()
            messages.append(message)
            lock.unlock()
            logs.fulfill()
        }

        DispatchQueue.concurrentPerform(iterations: 200) { _ in
            let model = NumberStrategyModel.deserialize(from: ["value": "oops"])
            lock.lock()
            values.append(model?.value)
            lock.unlock()
        }

        wait(for: [logs], timeout: 5)

        XCTAssertEqual(values.count, 200)
        for value in values {
            XCTAssertEqual(value, 99)
        }
        XCTAssertEqual(messages.count, 200)
        for message in messages {
            XCTAssertEqual(message.components(separatedBy: "[Smart Sentinel]").count - 1, 1, message)
            XCTAssertTrue(message.contains("NumberStrategyModel"), message)
        }
    }
}
