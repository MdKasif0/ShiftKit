import Foundation
import Observation

// MARK: - Batch Progress Summary
public struct BatchSummary: Sendable, Hashable {
    public let total: Int
    public let queued: Int
    public let inspecting: Int
    public let ready: Int
    public let running: Int
    public let completed: Int
    public let failed: Int
    public let cancelled: Int

    public var isFinished: Bool {
        (completed + failed + cancelled) == total && total > 0
    }

    public var percentComplete: Double {
        guard total > 0 else { return 1.0 }
        return Double(completed + failed + cancelled) / Double(total)
    }
}

// MARK: - Centralized Job Manager
@Observable
public final class JobManager: @unchecked Sendable {
    public static let shared = JobManager()

    // Observable UI states
    public private(set) var activeJobs: [ConversionJob] = []
    public private(set) var completedJobs: [ConversionJob] = []
    public private(set) var failedJobs: [ConversionJob] = []

    private let router: ConversionRouting
    private let outputManager: OutputManaging
    private let historyStore: JobHistoryStore
    private var semaphore: AsyncSemaphore
    private let queueLock = NSLock()
    private var runningTasks: [UUID: Task<Void, Never>] = [:]
    private var maxConcurrency: Int
    private var isQueuePaused: Bool = false

    public init(
        router: ConversionRouting = ConversionRouter(),
        outputManager: OutputManaging = OutputManager(),
        historyStore: JobHistoryStore = .shared,
        maxConcurrency: Int = 2
    ) {
        self.router = router
        self.outputManager = outputManager
        self.historyStore = historyStore
        let concurrency = max(1, maxConcurrency)
        self.maxConcurrency = concurrency
        self.semaphore = AsyncSemaphore(value: concurrency)
    }

    /// Enqueues a single conversion request
    @discardableResult
    public func enqueue(request: ConversionRequest) -> ConversionJob {
        let job = ConversionJob(request: request, status: .queued)

        queueLock.lock()
        activeJobs.insert(job, at: 0)
        queueLock.unlock()

        let task = Task.detached(priority: .userInitiated) { [weak self, jobID = job.id] in
            guard let self else { return }
            await self.processJob(id: jobID)
        }

        queueLock.lock()
        runningTasks[job.id] = task
        queueLock.unlock()

        return job
    }

    /// Enqueues a batch of multiple conversion requests
    @discardableResult
    public func enqueueBatch(requests: [ConversionRequest]) -> [ConversionJob] {
        requests.map { enqueue(request: $0) }
    }

    /// Cancels a running or queued job by ID
    public func cancelJob(id: UUID) {
        queueLock.lock()
        let task = runningTasks.removeValue(forKey: id)
        queueLock.unlock()

        task?.cancel()

        queueLock.lock()
        if let idx = activeJobs.firstIndex(where: { $0.id == id }) {
            var cancelledJob = activeJobs.remove(at: idx)
            cancelledJob.status = .cancelled
            cancelledJob.completedAt = Date()
            completedJobs.insert(cancelledJob, at: 0)
            historyStore.record(job: cancelledJob)
        }
        queueLock.unlock()
    }

    /// Cancels multiple jobs by ID
    public func cancelBatch(ids: [UUID]) {
        for id in ids {
            cancelJob(id: id)
        }
    }

    /// Cancels all currently active/queued operations
    public func cancelAllActiveJobs() {
        queueLock.lock()
        let ids = activeJobs.map { $0.id }
        queueLock.unlock()
        for id in ids {
            cancelJob(id: id)
        }
    }

    /// Checks if queue processing is currently paused
    public var isPaused: Bool {
        queueLock.lock()
        defer { queueLock.unlock() }
        return isQueuePaused
    }

    /// Pauses dispatching of new queued jobs
    public func pauseQueue() {
        queueLock.lock()
        isQueuePaused = true
        queueLock.unlock()
    }

    /// Resumes dispatching of queued jobs
    public func resumeQueue() {
        queueLock.lock()
        isQueuePaused = false
        queueLock.unlock()
    }

    /// Dynamically updates the maximum concurrent conversions
    public func updateMaxConcurrency(_ newLimit: Int) {
        queueLock.lock()
        let clamped = max(1, min(8, newLimit))
        self.maxConcurrency = clamped
        self.semaphore = AsyncSemaphore(value: clamped)
        queueLock.unlock()
    }

    /// Retries a previously failed job by ID
    @discardableResult
    public func retryJob(id: UUID) -> ConversionJob? {
        queueLock.lock()
        guard let idx = failedJobs.firstIndex(where: { $0.id == id }) else {
            queueLock.unlock()
            return nil
        }
        let failedJob = failedJobs.remove(at: idx)
        queueLock.unlock()
        return enqueue(request: failedJob.request)
    }

    /// Retries all failed jobs currently in the failure buffer
    @discardableResult
    public func retryAllFailedJobs() -> [ConversionJob] {
        queueLock.lock()
        let jobsToRetry = failedJobs
        failedJobs.removeAll()
        queueLock.unlock()
        return jobsToRetry.map { enqueue(request: $0.request) }
    }

    /// Computes summary of current jobs
    public var batchSummary: BatchSummary {
        queueLock.lock()
        defer { queueLock.unlock() }

        var queued = 0
        var inspecting = 0
        var ready = 0
        var running = 0
        var completed = 0
        var failed = 0
        var cancelled = 0

        for job in activeJobs {
            switch job.status {
            case .queued: queued += 1
            case .inspecting: inspecting += 1
            case .ready: ready += 1
            case .running: running += 1
            case .completed: completed += 1
            case .failed: failed += 1
            case .cancelled: cancelled += 1
            }
        }

        for job in completedJobs {
            switch job.status {
            case .completed: completed += 1
            case .cancelled: cancelled += 1
            default: break
            }
        }

        for _ in failedJobs {
            failed += 1
        }

        let total = queued + inspecting + ready + running + completed + failed + cancelled
        return BatchSummary(
            total: total,
            queued: queued,
            inspecting: inspecting,
            ready: ready,
            running: running,
            completed: completed,
            failed: failed,
            cancelled: cancelled
        )
    }

    /// Primary processing loop for an individual job with strict state transitions
    private func processJob(id: UUID) async {
        while true {
            let paused = isPaused
            if !paused { break }
            if Task.isCancelled {
                cancelJob(id: id)
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        await semaphore.wait()
        defer {
            Task { await semaphore.signal() }
            queueLock.lock()
            runningTasks.removeValue(forKey: id)
            queueLock.unlock()
        }

        guard var job = findJob(by: id) else { return }

        // 1. Transition: inspecting
        updateJob(job, status: .inspecting)

        // Validate source file exists and is readable
        for input in job.inputs {
            if !FileManager.default.fileExists(atPath: input.path) {
                failJob(id: id, error: .fileNotFound(input))
                return
            }
            if !FileManager.default.isReadableFile(atPath: input.path) {
                failJob(id: id, error: .permissionDenied(input))
                return
            }
        }

        // 2. Transition: ready
        updateJob(job, status: .ready)

        // 3. Transition: running
        let startTime = Date()
        job.startedAt = startTime
        updateJob(job, status: .running(progress: 0.05, stage: "Routing conversion..."))

        do {
            if Task.isCancelled {
                cancelJob(id: id)
                return
            }

            let engine = try router.route(request: job.request)
            let destinationURL = router.resolveDestination(for: job.request)

            let outputURL = try await engine.execute(
                request: job.request,
                outputURL: destinationURL,
                progressHandler: { [weak self, id] progress, stage in
                    self?.updateJobProgress(id: id, progress: progress ?? 0.0, stage: stage)
                }
            )

            if Task.isCancelled {
                cancelJob(id: id)
                return
            }

            // 4. Output Validation: Do not mark completed until verified
            let outputSize = try outputManager.validateOutput(at: outputURL)

            let duration = Date().timeIntervalSince(startTime)
            job.completedAt = Date()
            finishJob(id: id, outputURL: outputURL, duration: duration, outputSize: outputSize)

        } catch is CancellationError {
            cancelJob(id: id)
        } catch let error as ShiftKitError {
            if case .cancelled = error {
                cancelJob(id: id)
            } else {
                failJob(id: id, error: error)
            }
        } catch {
            failJob(id: id, error: .conversionFailed(reason: error.localizedDescription))
        }
    }

    // MARK: - State Updaters
    private func findJob(by id: UUID) -> ConversionJob? {
        queueLock.lock()
        defer { queueLock.unlock() }
        return activeJobs.first(where: { $0.id == id })
    }

    private func updateJob(_ job: ConversionJob, status: JobStatus) {
        queueLock.lock()
        if let idx = activeJobs.firstIndex(where: { $0.id == job.id }) {
            var updated = activeJobs[idx]
            updated.status = status
            activeJobs[idx] = updated
        }
        queueLock.unlock()
    }

    private func updateJobProgress(id: UUID, progress: Double, stage: String) {
        queueLock.lock()
        if let idx = activeJobs.firstIndex(where: { $0.id == id }) {
            activeJobs[idx].status = .running(progress: progress, stage: stage)
        }
        queueLock.unlock()
    }

    private func finishJob(id: UUID, outputURL: URL, duration: TimeInterval, outputSize: Int64) {
        queueLock.lock()
        if let idx = activeJobs.firstIndex(where: { $0.id == id }) {
            var finished = activeJobs.remove(at: idx)
            finished.status = .completed(outputURL: outputURL, duration: duration, outputSize: outputSize)
            finished.completedAt = Date()
            completedJobs.insert(finished, at: 0)
            historyStore.record(job: finished)
        }
        queueLock.unlock()
    }

    private func failJob(id: UUID, error: ShiftKitError) {
        queueLock.lock()
        if let idx = activeJobs.firstIndex(where: { $0.id == id }) {
            var failed = activeJobs.remove(at: idx)
            failed.status = .failed(error: error)
            failed.completedAt = Date()
            failedJobs.insert(failed, at: 0)
            completedJobs.insert(failed, at: 0)
            historyStore.record(job: failed)
        }
        queueLock.unlock()
    }

    public func clearCompletedJobs() {
        queueLock.lock()
        completedJobs.removeAll()
        failedJobs.removeAll()
        queueLock.unlock()
    }

    public func populateSampleJobsForPreview() {
        let sampleReq1 = ConversionRequest(
            sourceURL: URL(fileURLWithPath: "/Users/demo/Photos/hero-banner.png"),
            fileType: .image(.png),
            action: .imageToWebP
        )
        var sampleJob1 = ConversionJob(request: sampleReq1)
        sampleJob1.status = .completed(
            outputURL: URL(fileURLWithPath: "/Users/demo/Downloads/ShiftKit/hero-banner_convert.webp"),
            duration: 0.42,
            outputSize: 245_000
        )

        let sampleReq2 = ConversionRequest(
            sourceURL: URL(fileURLWithPath: "/Users/demo/Documents/quarterly-brief.pdf"),
            fileType: .pdf,
            action: .pdfCompress
        )
        var sampleJob2 = ConversionJob(request: sampleReq2)
        sampleJob2.status = .completed(
            outputURL: URL(fileURLWithPath: "/Users/demo/Downloads/ShiftKit/quarterly-brief_compress.pdf"),
            duration: 0.88,
            outputSize: 1_420_000
        )

        completedJobs = [sampleJob1, sampleJob2]
    }
}
