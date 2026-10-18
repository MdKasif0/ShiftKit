import Foundation

/// A lightweight, Swift Concurrency-native semaphore for controlling maximum concurrent tasks.
public actor AsyncSemaphore {
    private let maxCount: Int
    private var currentCount: Int
    private var continuations: [CheckedContinuation<Void, Never>] = []

    public init(value: Int) {
        precondition(value > 0, "Semaphore count must be greater than zero.")
        self.maxCount = value
        self.currentCount = value
    }

    public func wait() async {
        if currentCount > 0 {
            currentCount -= 1
            return
        }
        await withCheckedContinuation { continuation in
            continuations.append(continuation)
        }
    }

    public func signal() {
        if !continuations.isEmpty {
            let next = continuations.removeFirst()
            next.resume()
        } else {
            currentCount = min(maxCount, currentCount + 1)
        }
    }
}
