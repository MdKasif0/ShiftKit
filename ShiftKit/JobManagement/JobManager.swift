import Foundation
import Observation

@Observable
public final class JobManager: @unchecked Sendable {
    // Observable UI states
    public private(set) var activeJobs: [ConversionJob] = []
    public private(set) var completedJobs: [ConversionJob] = []

    private let router: ConversionRouting
    private let outputManager: OutputManaging
    private let semaphore = AsyncSemaphore(value: 2)
    private let queueLock = NSLock()

    public init(
        router: ConversionRouting = ConversionRouter(),
        outputManager: OutputManaging = OutputManager()
    ) {
        self.router = router
        self.outputManager = outputManager
    }

    /// Enqueues a new conversion request and begins background processing.
    @discardableResult
    public func enqueue(request: ConversionRequest) -> ConversionJob {
        let job = ConversionJob(request: request, status: .queued)

        queueLock.lock()
        activeJobs.insert(job, at: 0)
        queueLock.unlock()

        Task.detached(priority: .userInitiated) { [weak self, jobID = job.id] in
            await self?.processJob(id: jobID)
        }

        return job
    }

    /// Primary processing loop for a job
    private func processJob(id: UUID) async {
        await semaphore.wait()
        defer {
            Task { await semaphore.signal() }
        }

        guard var job = findJob(by: id) else { return }

        let startTime = Date()
        job.startedAt = startTime
        updateJob(job, status: .processing(progress: 0.05, stage: "Routing request..."))

        do {
            let engine = try router.route(request: job.request)
            let destinationURL = router.resolveDestination(for: job.request)

            let outputURL = try await engine.execute(
                request: job.request,
                outputURL: destinationURL,
                progressHandler: { [weak self, id] progress, stage in
                    self?.updateJobProgress(id: id, progress: progress, stage: stage)
                }
            )

            let duration = Date().timeIntervalSince(startTime)
            job.completedAt = Date()
            finishJob(id: id, outputURL: outputURL, duration: duration)

        } catch let error as ShiftKitError {
            failJob(id: id, error: error)
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
            activeJobs[idx].status = .processing(progress: progress, stage: stage)
        }
        queueLock.unlock()
    }

    private func finishJob(id: UUID, outputURL: URL, duration: TimeInterval) {
        queueLock.lock()
        if let idx = activeJobs.firstIndex(where: { $0.id == id }) {
            var finished = activeJobs.remove(at: idx)
            finished.status = .completed(outputURL: outputURL, duration: duration)
            completedJobs.insert(finished, at: 0)
        }
        queueLock.unlock()
    }

    private func failJob(id: UUID, error: ShiftKitError) {
        queueLock.lock()
        if let idx = activeJobs.firstIndex(where: { $0.id == id }) {
            var failed = activeJobs.remove(at: idx)
            failed.status = .failed(error: error)
            completedJobs.insert(failed, at: 0)
        }
        queueLock.unlock()
    }

    public func clearCompletedJobs() {
        queueLock.lock()
        completedJobs.removeAll()
        queueLock.unlock()
    }

    /// Injects sample completed jobs for UI preview / testing
    public func populateSampleJobsForPreview() {
        let sampleReq1 = ConversionRequest(
            sourceURL: URL(fileURLWithPath: "/Users/demo/Photos/hero-banner.png"),
            fileType: .image(.png),
            action: .imageToWebP
        )
        var sampleJob1 = ConversionJob(request: sampleReq1)
        sampleJob1.status = .completed(
            outputURL: URL(fileURLWithPath: "/Users/demo/Downloads/ShiftKit/hero-banner_convert.webp"),
            duration: 0.42
        )

        let sampleReq2 = ConversionRequest(
            sourceURL: URL(fileURLWithPath: "/Users/demo/Documents/quarterly-brief.pdf"),
            fileType: .pdf,
            action: .pdfCompress
        )
        var sampleJob2 = ConversionJob(request: sampleReq2)
        sampleJob2.status = .completed(
            outputURL: URL(fileURLWithPath: "/Users/demo/Downloads/ShiftKit/quarterly-brief_compress.pdf"),
            duration: 0.88
        )

        completedJobs = [sampleJob1, sampleJob2]
    }
}
