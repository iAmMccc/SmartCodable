import Foundation
import SmartCodable

private struct ProbeModel: SmartCodableX {
    var value: Int = 73
}

// Diagnostic only. ThreadSanitizer and returned values answer different
// questions; a quiet run does not establish a thread-safety guarantee.
let decoder = SmartJSONDecoder()
SmartSentinel.debugMode = .none
let lock = NSLock()
var mismatches: [(Int, Int?)] = []

DispatchQueue.concurrentPerform(iterations: 64) { index in
    let result = try? decoder.smartDecode(ProbeModel.self, from: ["value": index])
    if result?.value != index {
        lock.lock()
        mismatches.append((index, result?.value))
        lock.unlock()
    }
}

print("model=ProbeModel,instances=1,iterations=64,mismatches=\(mismatches.count)")
if !mismatches.isEmpty {
    print("first mismatch=\(String(describing: mismatches.first))")
    exit(1)
}
