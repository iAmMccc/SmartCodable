#if os(macOS)
import Darwin
import Foundation
import XCTest
@testable import SmartCodable

private final class SentinelCallbackCounter {
    private let lock = NSLock()
    private var value = 0

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func recordCallback() {
        lock.lock()
        value += 1
        lock.unlock()
    }
}

private struct SentinelProbeModel: Decodable {
    let value: Int
}

enum SentinelSubprocessProbe {
    private struct ChildObservation {
        let mode: String
        let stdout: String
        let stderr: String
        let businessOutput: String?
        let status: Int32
        let terminationReason: Process.TerminationReason
    }

    static func assertPrintAndHandlerSemantics(_ testCase: XCTestCase) throws {
        let executable = try XCTUnwrap(ProcessInfo.processInfo.arguments.first)
        let bundle = Bundle(for: SentinelSubprocessTests.self).bundleURL
        XCTAssertEqual(bundle.pathExtension, "xctest")

        let none = try runChild(mode: "none", executable: executable, bundle: bundle, testCase: testCase)
        let alert = try runChild(mode: "alert", executable: executable, bundle: bundle, testCase: testCase)

        XCTAssertEqual(none.terminationReason, .exit, none.stderr)
        XCTAssertEqual(none.status, 0, none.stderr)
        XCTAssertTrue(
            none.stderr.contains("SENTINEL_PROBE_RESULT mode=none callback_count=0"),
            "the child probe marker records the none-mode callback count separately from stdout: \(none.stderr)"
        )
        XCTAssertNotNil(none.businessOutput, "stdout capture markers must surround the decode region: \(none.stdout)")
        XCTAssertEqual(
            none.businessOutput,
            "",
            "none mode must not write any stdout during the decode region: \(none.stdout)"
        )

        XCTAssertEqual(alert.terminationReason, .exit, alert.stderr)
        XCTAssertEqual(alert.status, 0, alert.stderr)
        XCTAssertTrue(
            alert.stderr.contains("SENTINEL_PROBE_RESULT mode=alert callback_count=1"),
            "the child probe marker records the alert-mode callback count separately from stdout: \(alert.stderr)"
        )
        let alertOutput = alert.businessOutput?.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertFalse(alertOutput?.isEmpty ?? true, "alert mode must write stdout during the decode region: \(alert.stdout)")
        XCTAssertTrue(
            alertOutput?.contains("[Smart Sentinel]") ?? false,
            "alert mode stdout must include the Sentinel banner: \(alert.stdout)"
        )

        for observation in [none, alert] {
            print("SENTINEL_PARENT_RAW_BEGIN mode=\(observation.mode)")
            print("CHILD_STDOUT_BEGIN")
            print(observation.stdout, terminator: "")
            print("CHILD_STDOUT_END")
            print("CHILD_STDERR_BEGIN")
            print(observation.stderr, terminator: "")
            print("CHILD_STDERR_END")
            print("SENTINEL_PARENT_RAW_END mode=\(observation.mode)")
        }
    }

    private static func runChild(
        mode: String,
        executable: String,
        bundle: URL,
        testCase: XCTestCase
    ) throws -> ChildObservation {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("smart-sentinel-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let stdoutURL = directory.appendingPathComponent("stdout.log")
        let stderrURL = directory.appendingPathComponent("stderr.log")
        FileManager.default.createFile(atPath: stdoutURL.path, contents: nil)
        FileManager.default.createFile(atPath: stderrURL.path, contents: nil)
        let stdoutHandle = try FileHandle(forWritingTo: stdoutURL)
        let stderrHandle = try FileHandle(forWritingTo: stderrURL)
        defer {
            stdoutHandle.closeFile()
            stderrHandle.closeFile()
        }

        let child = Process()
        child.executableURL = URL(fileURLWithPath: executable)
        child.arguments = [
            "-XCTest",
            "SmartCodableTests.SentinelSubprocessTests/testChildProbe",
            bundle.path
        ]
        child.environment = ProcessInfo.processInfo.environment.merging([
            "SMART_SENTINEL_PROBE_MODE": mode,
            "LLVM_PROFILE_FILE": directory.appendingPathComponent("child-%p.profraw").path
        ]) { _, override in override }
        child.standardOutput = stdoutHandle
        child.standardError = stderrHandle

        let completed = testCase.expectation(description: "Sentinel child probe: \(mode)")
        child.terminationHandler = { _ in completed.fulfill() }
        try child.run()
        if XCTWaiter.wait(for: [completed], timeout: 5) != .completed {
            child.terminate()
            child.waitUntilExit()
            XCTFail("Sentinel child probe timed out: mode=\(mode)")
        }

        let stdout = (try? String(contentsOf: stdoutURL, encoding: .utf8)) ?? ""
        let stderr = (try? String(contentsOf: stderrURL, encoding: .utf8)) ?? ""
        return ChildObservation(
            mode: mode,
            stdout: stdout,
            stderr: stderr,
            businessOutput: capturedBusinessOutput(from: stdout, mode: mode),
            status: child.terminationStatus,
            terminationReason: child.terminationReason
        )
    }

    private static func capturedBusinessOutput(from stdout: String, mode: String) -> String? {
        let beginMarker = "SENTINEL_CAPTURE_BEGIN mode=\(mode)\n"
        let endMarker = "SENTINEL_CAPTURE_END mode=\(mode)"
        guard let begin = stdout.range(of: beginMarker),
              let end = stdout.range(of: endMarker, range: begin.upperBound..<stdout.endIndex) else {
            return nil
        }
        return String(stdout[begin.upperBound..<end.lowerBound])
    }
}

final class SentinelSubprocessTests: XCTestCase {
    func testChildProbe() throws {
        guard let mode = ProcessInfo.processInfo.environment["SMART_SENTINEL_PROBE_MODE"],
              mode == "none" || mode == "alert" else {
            throw XCTSkip("Executed by testSmartSentinelNoneModeSuppressesPrintAndHandler in isolated child processes")
        }

        let previousMode = SmartSentinel.debugMode
        defer {
            SmartSentinel.debugMode = previousMode
            SmartSentinel.onLogGenerated { _ in }
        }

        let counter = SentinelCallbackCounter()
        SmartSentinel.debugMode = mode == "none" ? .none : .alert
        SmartSentinel.onLogGenerated { _ in
            counter.recordCallback()
        }

        // The same invalid top-level JSON value drives monitorAndPrint in both child modes.
        FileHandle.standardOutput.write(Data("SENTINEL_CAPTURE_BEGIN mode=\(mode)\n".utf8))
        XCTAssertThrowsError(try SmartJSONDecoder().smartDecode(SentinelProbeModel.self, from: 42))
        fflush(stdout)
        let mainQueueBarrier = expectation(description: "main queue drained after Sentinel producer for \(mode)")
        DispatchQueue.main.async { mainQueueBarrier.fulfill() }
        wait(for: [mainQueueBarrier], timeout: 1)
        FileHandle.standardOutput.write(Data("SENTINEL_CAPTURE_END mode=\(mode)\n".utf8))

        let expectedCount = mode == "none" ? 0 : 1
        let observedCount = counter.count
        FileHandle.standardError.write(
            Data("SENTINEL_PROBE_RESULT mode=\(mode) callback_count=\(observedCount)\n".utf8)
        )
        XCTAssertEqual(observedCount, expectedCount)
    }
}
#endif
