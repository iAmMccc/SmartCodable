import Foundation

/// Waits for work already queued on the main queue to finish, with a visible timeout.
enum DemoMainQueueCompletionBarrier {
    static func wait(timeout: TimeInterval) -> Bool {
        let completion = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            completion.signal()
        }

        guard Thread.isMainThread else {
            return completion.wait(timeout: .now() + timeout) == .success
        }

        let deadline = Date().addingTimeInterval(timeout)
        while completion.wait(timeout: .now()) != .success {
            let remaining = deadline.timeIntervalSinceNow
            guard remaining > 0 else { return false }

            let nextRunLoopDeadline = Date().addingTimeInterval(min(remaining, 0.05))
            RunLoop.current.run(mode: .default, before: nextRunLoopDeadline)
        }
        return true
    }
}

final class DemoLogRecorder {
    private let lock = NSLock()
    private var storage: [String] = []

    func record(_ message: String) {
        lock.lock()
        storage.append(message)
        lock.unlock()
    }

    var messages: [String] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}
