#if os(macOS)
import Foundation
import SmartCodable
import XCTest

private struct SubprocessInt64: SmartCodableX {
    var value: Int64 = 77
}

private struct SubprocessUInt64: SmartCodableX {
    var value: UInt64 = 99
}

private struct NumericProbeCase {
    let name: String
    let signed: Bool
    let policy: SmartCodableOptions.NumberConversionStrategy
    let decimal: String
    let representation: String
    let expected: String
}

final class NumericSubprocessTests: XCTestCase {
    // Raw out-of-range decimals must fall back even when their rounded integer fits.
    private static let cases: [NumericProbeCase] = [
        .init(name: "signed-upper-strict", signed: true, policy: .strict,
              decimal: "9223372036854775808", representation: "string", expected: "77"),
        .init(name: "signed-upper-truncate", signed: true, policy: .truncate,
              decimal: "9223372036854775808", representation: "string", expected: "77"),
        .init(name: "signed-upper-rounded", signed: true, policy: .rounded,
              decimal: "9223372036854775808", representation: "string", expected: "77"),
        .init(name: "unsigned-upper-strict", signed: false, policy: .strict,
              decimal: "18446744073709551616", representation: "string", expected: "99"),
        .init(name: "unsigned-upper-truncate", signed: false, policy: .truncate,
              decimal: "18446744073709551616", representation: "string", expected: "99"),
        .init(name: "unsigned-upper-rounded", signed: false, policy: .rounded,
              decimal: "18446744073709551616", representation: "string", expected: "99"),
        .init(name: "signed-valid-max", signed: true, policy: .strict,
              decimal: "9223372036854775807", representation: "string", expected: "9223372036854775807"),
        .init(name: "signed-valid-min", signed: true, policy: .strict,
              decimal: "-9223372036854775808", representation: "string", expected: "-9223372036854775808"),
        .init(name: "signed-underflow-strict", signed: true, policy: .strict,
              decimal: "-9223372036854775809", representation: "string", expected: "77"),
        .init(name: "signed-underflow-truncate", signed: true, policy: .truncate,
              decimal: "-9223372036854775809", representation: "string", expected: "77"),
        .init(name: "signed-underflow-rounded", signed: true, policy: .rounded,
              decimal: "-9223372036854775809", representation: "string", expected: "77"),
        .init(name: "signed-underflow-decimal-strict", signed: true, policy: .strict,
              decimal: "-9223372036854775809.0", representation: "string", expected: "77"),
        .init(name: "signed-underflow-decimal-truncate", signed: true, policy: .truncate,
              decimal: "-9223372036854775809.0", representation: "string", expected: "77"),
        .init(name: "signed-underflow-decimal-rounded", signed: true, policy: .rounded,
              decimal: "-9223372036854775809.0", representation: "string", expected: "77"),
        .init(name: "signed-underflow-exponent-strict", signed: true, policy: .strict,
              decimal: "-9.223372036854775809e18", representation: "string", expected: "77"),
        .init(name: "signed-underflow-exponent-truncate", signed: true, policy: .truncate,
              decimal: "-9.223372036854775809e18", representation: "string", expected: "77"),
        .init(name: "signed-underflow-exponent-rounded", signed: true, policy: .rounded,
              decimal: "-9.223372036854775809e18", representation: "string", expected: "77"),
        .init(name: "signed-min-fraction-strict", signed: true, policy: .strict,
              decimal: "-9223372036854775808.1", representation: "string", expected: "77"),
        .init(name: "signed-min-fraction-truncate", signed: true, policy: .truncate,
              decimal: "-9223372036854775808.1", representation: "string", expected: "77"),
        .init(name: "signed-min-fraction-rounded", signed: true, policy: .rounded,
              decimal: "-9223372036854775808.1", representation: "string", expected: "77"),
        .init(name: "signed-min-half-rounded", signed: true, policy: .rounded,
              decimal: "-9223372036854775808.5", representation: "string", expected: "77"),
        .init(name: "signed-max-fraction-strict", signed: true, policy: .strict,
              decimal: "9223372036854775807.4", representation: "string", expected: "77"),
        .init(name: "signed-max-fraction-truncate", signed: true, policy: .truncate,
              decimal: "9223372036854775807.4", representation: "string", expected: "77"),
        .init(name: "signed-max-fraction-rounded", signed: true, policy: .rounded,
              decimal: "9223372036854775807.4", representation: "string", expected: "77"),
        .init(name: "unsigned-valid-max", signed: false, policy: .strict,
              decimal: "18446744073709551615", representation: "string", expected: "18446744073709551615"),
        .init(name: "unsigned-max-fraction-strict", signed: false, policy: .strict,
              decimal: "18446744073709551615.4", representation: "string", expected: "99"),
        .init(name: "unsigned-max-fraction-truncate", signed: false, policy: .truncate,
              decimal: "18446744073709551615.4", representation: "string", expected: "99"),
        .init(name: "unsigned-max-fraction-rounded", signed: false, policy: .rounded,
              decimal: "18446744073709551615.4", representation: "string", expected: "99"),
        .init(name: "signed-native-overflow", signed: true, policy: .truncate,
              decimal: "9223372036854775808", representation: "data", expected: "77"),
        .init(name: "signed-native-underflow", signed: true, policy: .strict,
              decimal: "-9223372036854775809", representation: "data", expected: "77")
    ]

    /// Parent test launches the test bundle again, selecting only testChildProbe.
    /// A Swift integer trap can kill that process without killing the parent suite.
    func testIntegerBoundaryCasesInIsolatedProcesses() throws {
        let executable = try XCTUnwrap(ProcessInfo.processInfo.arguments.first)
        let bundle = Bundle(for: Self.self).bundleURL
        XCTAssertEqual(bundle.pathExtension, "xctest")
        for (index, sample) in Self.cases.enumerated() {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("smart-numeric-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let output = directory.appendingPathComponent("stdout.log")
            let errors = directory.appendingPathComponent("stderr.log")
            FileManager.default.createFile(atPath: output.path, contents: nil)
            FileManager.default.createFile(atPath: errors.path, contents: nil)
            let outputHandle = try FileHandle(forWritingTo: output)
            let errorHandle = try FileHandle(forWritingTo: errors)
            defer {
                outputHandle.closeFile()
                errorHandle.closeFile()
            }

            let child = Process()
            child.executableURL = URL(fileURLWithPath: executable)
            child.arguments = ["-XCTest", "SmartCodableTests.NumericSubprocessTests/testChildProbe", bundle.path]
            child.environment = ProcessInfo.processInfo.environment.merging([
                "SMART_NUMERIC_PROBE_CASE": String(index),
                "LLVM_PROFILE_FILE": directory.appendingPathComponent("child-%p.profraw").path
            ]) { _, override in override }
            child.standardOutput = outputHandle
            child.standardError = errorHandle

            let completed = expectation(description: sample.name)
            child.terminationHandler = { _ in completed.fulfill() }
            try child.run()
            if XCTWaiter.wait(for: [completed], timeout: 5) != .completed {
                child.terminate()
                child.waitUntilExit()
                XCTFail("timeout: \(sample.name), input=\(sample.decimal), policy=\(sample.policy)")
                continue
            }
            let stdout = (try? String(contentsOf: output, encoding: .utf8)) ?? ""
            let stderr = (try? String(contentsOf: errors, encoding: .utf8)) ?? ""
            let details = "\(sample.name) input=\(sample.decimal) representation=\(sample.representation) "
                + "policy=\(sample.policy) termination=\(child.terminationReason) "
                + "status=\(child.terminationStatus) stderr=\(stderr.prefix(500))"
            XCTAssertEqual(child.terminationReason, .exit, details)
            XCTAssertEqual(child.terminationStatus, 0, details)
            XCTAssertTrue(stdout.contains("observed=\(sample.expected)\n"), "\(details) stdout=\(stdout.prefix(500))")
        }
    }

    func testChildProbe() throws {
        guard let indexText = ProcessInfo.processInfo.environment["SMART_NUMERIC_PROBE_CASE"],
              let index = Int(indexText), Self.cases.indices.contains(index) else {
            throw XCTSkip("Executed only by testIntegerBoundaryCasesInIsolatedProcesses")
        }
        let sample = Self.cases[index]
        SmartCodableOptions.numberStrategy = sample.policy
        let json = Data("{\"value\":\(sample.decimal)}".utf8)
        if sample.signed {
            let result = sample.representation == "data"
                ? SubprocessInt64.deserialize(from: json)
                : SubprocessInt64.deserialize(from: ["value": sample.decimal])
            print("observed=\(result.map { String($0.value) } ?? "nil")")
        } else {
            let result = sample.representation == "data"
                ? SubprocessUInt64.deserialize(from: json)
                : SubprocessUInt64.deserialize(from: ["value": sample.decimal])
            print("observed=\(result.map { String($0.value) } ?? "nil")")
        }
    }
}
#endif
