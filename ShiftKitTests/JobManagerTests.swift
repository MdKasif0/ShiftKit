import XCTest
@testable import ShiftKit

final class JobManagerTests: XCTestCase {
    private var tempDir: URL!
    private var jobManager: JobManager!
    private var outputManager: OutputManager!
    private var historyStore: JobHistoryStore!

    override func setUp() async throws {
        try await super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let historyURL = tempDir.appendingPathComponent("test_history.json")
        historyStore = JobHistoryStore(customFileURL: historyURL)
        outputManager = OutputManager()
        jobManager = JobManager(
            outputManager: outputManager,
            historyStore: historyStore,
            maxConcurrency: 2
        )
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
        try await super.tearDown()
    }

    // MARK: - Helper to Create a Real Valid PNG Image
    private func createTestPNG(named name: String = "test.png") -> URL {
        let url = tempDir.appendingPathComponent(name)
        let image = NSImage(size: NSSize(width: 32, height: 32))
        image.lockFocus()
        NSColor.red.drawSwatch(in: NSRect(x: 0, y: 0, width: 32, height: 32))
        image.unlockFocus()
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            fatalError("Could not create test PNG")
        }
        try! png.write(to: url)
        return url
    }

    // MARK: - Lifecycle & Property Tracking Tests

    func testJobEnqueueingAndProperties() {
        let inputURL = createTestPNG(named: "input.png")
        let destURL = tempDir.appendingPathComponent("output.jpg")
        let request = ConversionRequest(
            sourceURL: inputURL,
            fileType: .image(.png),
            action: .imageToJPEG,
            destinationURL: destURL
        )

        let job = jobManager.enqueue(request: request)

        XCTAssertFalse(job.id.uuidString.isEmpty)
        XCTAssertEqual(job.inputs, [inputURL])
        XCTAssertEqual(job.operation, .imageToJPEG)
        XCTAssertEqual(job.sourceFileName, "input.png")
        XCTAssertEqual(job.actionTitle, "To JPEG")
        XCTAssertEqual(job.progress, 0.0)
        XCTAssertNil(job.startedAt)
        XCTAssertNil(job.completedAt)
        XCTAssertNil(job.error)

        let isTracked = jobManager.activeJobs.contains(where: { item in item.id == job.id }) || jobManager.completedJobs.contains(where: { item in item.id == job.id })
        XCTAssertTrue(isTracked)
    }

    func testExecutionAndOutputValidation() async throws {
        let inputURL = createTestPNG(named: "valid.png")
        let destURL = tempDir.appendingPathComponent("valid.jpg")
        let request = ConversionRequest(
            sourceURL: inputURL,
            fileType: .image(.png),
            action: .imageToJPEG,
            destinationURL: destURL
        )

        let job = jobManager.enqueue(request: request)

        // Wait for job completion
        let deadline = Date().addingTimeInterval(5.0)
        while Date() < deadline {
            if let completed = jobManager.completedJobs.first(where: { $0.id == job.id }) {
                guard case .completed(let outURL, _, let size) = completed.status else {
                    XCTFail("Expected completed status, got \(completed.status)")
                    return
                }
                XCTAssertEqual(outURL, destURL)
                XCTAssertTrue(FileManager.default.fileExists(atPath: outURL.path))
                XCTAssertGreaterThan(size, 0)
                XCTAssertNotNil(completed.completedAt)
                XCTAssertTrue(completed.status.isTerminal)

                // Verify recorded in history store
                let history = historyStore.items
                XCTAssertTrue(history.contains(where: { $0.id == job.id && $0.status == "completed" }))
                return
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        XCTFail("Job did not finish before deadline")
    }

    func testOutputValidationFailsWhenOutputFileIsEmptyOrMissing() async throws {
        struct MockFailingOutputManager: OutputManaging {
            func defaultOutputDirectory() -> URL { URL(fileURLWithPath: "/tmp") }
            func resolveDestinationURL(for sourceURL: URL, targetExtension: String?, suffix: String?, customDirectory: URL?) -> URL {
                sourceURL.deletingPathExtension().appendingPathExtension(targetExtension ?? "out")
            }
            func resolveDestinationURL(for sourceURL: URL, targetExtension: String?, suffix: String?, strategy: OutputLocationStrategy) async throws -> URL {
                sourceURL.deletingPathExtension().appendingPathExtension(targetExtension ?? "out")
            }
            func resolveDestination(for sourceURL: URL, targetExtension: String?, suffix: String?, customDirectory: URL?, conflictResolution: FilenameConflictResolution) throws -> URL {
                sourceURL.deletingPathExtension().appendingPathExtension(targetExtension ?? "out")
            }
            func detectConflicts(sources: [URL], targetExtension: String?, suffix: String?, targetDirectory: URL?) -> [URL: [URL]] { [:] }
            func createTemporaryOutputURL(for destinationURL: URL) throws -> URL { destinationURL }
            func commitTemporaryOutput(temporaryURL: URL, destinationURL: URL) throws {}
            func cleanupTemporaryOutput(temporaryURL: URL) {}
            func revealInFinder(url: URL) {}
            func openFile(url: URL) {}
            func validateOutput(at url: URL) throws -> Int64 {
                throw ShiftKitError.conversionFailed(reason: "Output validation failed: produced file is missing or empty.")
            }
        }

        let failingManager = JobManager(
            outputManager: MockFailingOutputManager(),
            historyStore: historyStore,
            maxConcurrency: 1
        )

        let inputURL = createTestPNG(named: "corrupt.png")
        let destURL = tempDir.appendingPathComponent("corrupt.jpg")
        let request = ConversionRequest(
            sourceURL: inputURL,
            fileType: .image(.png),
            action: .imageToJPEG,
            destinationURL: destURL
        )

        let job = failingManager.enqueue(request: request)

        // Wait for failure
        let deadline = Date().addingTimeInterval(5.0)
        while Date() < deadline {
            if let completed = failingManager.completedJobs.first(where: { $0.id == job.id }) {
                guard case .failed(let error) = completed.status else {
                    XCTFail("Expected failed status due to output validation, got \(completed.status)")
                    return
                }
                XCTAssertNotNil(completed.error)
                XCTAssertTrue(error.localizedDescription.contains("Output validation failed") || error.localizedDescription.contains("failed"))
                return
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        XCTFail("Job did not finish before deadline")
    }

    func testJobCancellation() async throws {
        let inputURL = createTestPNG(named: "cancel_me.png")
        let destURL = tempDir.appendingPathComponent("cancel_me.jpg")
        let request = ConversionRequest(
            sourceURL: inputURL,
            fileType: .image(.png),
            action: .imageToJPEG,
            destinationURL: destURL
        )

        let job = jobManager.enqueue(request: request)
        jobManager.cancelJob(id: job.id)

        // Verify either active state transitioned or completed state recorded
        let deadline = Date().addingTimeInterval(3.0)
        while Date() < deadline {
            let active = jobManager.activeJobs.first(where: { $0.id == job.id })
            let completed = jobManager.completedJobs.first(where: { $0.id == job.id })

            if active?.status == .cancelled || completed?.status == .cancelled {
                XCTAssertTrue(active?.isCancelled == true || completed?.isCancelled == true)
                return
            }
            try await Task.sleep(nanoseconds: 30_000_000)
        }
    }

    func testBatchEnqueueAndCancelAll() async throws {
        var requests: [ConversionRequest] = []
        for i in 1...4 {
            let url = createTestPNG(named: "batch_\(i).png")
            let dest = tempDir.appendingPathComponent("batch_\(i).jpg")
            requests.append(ConversionRequest(
                sourceURL: url,
                fileType: .image(.png),
                action: .imageToJPEG,
                destinationURL: dest
            ))
        }

        let jobs = jobManager.enqueueBatch(requests: requests)
        XCTAssertEqual(jobs.count, 4)
        XCTAssertEqual(jobManager.batchSummary.total, 4)

        jobManager.cancelAllActiveJobs()

        // Wait briefly for cancellation to take effect
        try await Task.sleep(nanoseconds: 100_000_000)

        for job in jobManager.activeJobs {
            XCTAssertTrue(job.isCancelled || job.status == .cancelled)
        }
    }

    func testClearCompletedJobs() async throws {
        let inputURL = createTestPNG(named: "clear_test.png")
        let destURL = tempDir.appendingPathComponent("clear_test.jpg")
        let request = ConversionRequest(
            sourceURL: inputURL,
            fileType: .image(.png),
            action: .imageToJPEG,
            destinationURL: destURL
        )

        let job = jobManager.enqueue(request: request)

        // Wait for completion
        let deadline = Date().addingTimeInterval(5.0)
        while Date() < deadline {
            if jobManager.completedJobs.contains(where: { $0.id == job.id }) {
                break
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        XCTAssertFalse(jobManager.completedJobs.isEmpty)
        jobManager.clearCompletedJobs()
        XCTAssertTrue(jobManager.completedJobs.isEmpty)
    }

    func testQueuePauseAndResume() async throws {
        jobManager.pauseQueue()
        XCTAssertTrue(jobManager.isPaused)

        let inputURL = createTestPNG(named: "pause_test.png")
        let destURL = tempDir.appendingPathComponent("pause_test.jpg")
        let request = ConversionRequest(
            sourceURL: inputURL,
            fileType: .image(.png),
            action: .imageToJPEG,
            destinationURL: destURL
        )

        let job = jobManager.enqueue(request: request)

        // Give it 150ms to ensure it does not run while paused
        try await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertFalse(jobManager.completedJobs.contains(where: { $0.id == job.id }))

        jobManager.resumeQueue()
        XCTAssertFalse(jobManager.isPaused)

        // Wait for completion now that queue is resumed
        let deadline = Date().addingTimeInterval(5.0)
        var finished = false
        while Date() < deadline {
            if jobManager.completedJobs.contains(where: { $0.id == job.id }) {
                finished = true
                break
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertTrue(finished)
    }

    func testRetryFailedJob() async throws {
        let missingURL = tempDir.appendingPathComponent("missing_to_retry.png")
        let destURL = tempDir.appendingPathComponent("missing_to_retry.jpg")
        let request = ConversionRequest(
            sourceURL: missingURL,
            fileType: .image(.png),
            action: .imageToJPEG,
            destinationURL: destURL
        )

        let job = jobManager.enqueue(request: request)

        // Wait for failure
        let deadline = Date().addingTimeInterval(3.0)
        var failed = false
        while Date() < deadline {
            if jobManager.failedJobs.contains(where: { $0.id == job.id }) {
                failed = true
                break
            }
            try await Task.sleep(nanoseconds: 30_000_000)
        }
        XCTAssertTrue(failed)

        // Now create the file and retry
        _ = createTestPNG(named: "missing_to_retry.png")
        guard let retried = jobManager.retryJob(id: job.id) else {
            XCTFail("retryJob returned nil")
            return
        }

        // Wait for retried job to complete
        let retryDeadline = Date().addingTimeInterval(5.0)
        var retriedFinished = false
        while Date() < retryDeadline {
            if let completed = jobManager.completedJobs.first(where: { $0.id == retried.id }) {
                if case .completed = completed.status {
                    retriedFinished = true
                    break
                }
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertTrue(retriedFinished)
    }

    func testRetryAllFailedJobs() async throws {
        let missing1 = tempDir.appendingPathComponent("fail1.png")
        let missing2 = tempDir.appendingPathComponent("fail2.png")

        let r1 = ConversionRequest(
            sourceURL: missing1,
            fileType: .image(.png),
            action: .imageToJPEG,
            destinationURL: tempDir.appendingPathComponent("fail1.jpg")
        )
        let r2 = ConversionRequest(
            sourceURL: missing2,
            fileType: .image(.png),
            action: .imageToJPEG,
            destinationURL: tempDir.appendingPathComponent("fail2.jpg")
        )

        _ = jobManager.enqueue(request: r1)
        _ = jobManager.enqueue(request: r2)

        // Wait for both to be in failedJobs
        let deadline = Date().addingTimeInterval(3.0)
        while Date() < deadline {
            if jobManager.failedJobs.count >= 2 {
                break
            }
            try await Task.sleep(nanoseconds: 30_000_000)
        }
        XCTAssertEqual(jobManager.failedJobs.count, 2)

        // Create both files
        _ = createTestPNG(named: "fail1.png")
        _ = createTestPNG(named: "fail2.png")

        let retried = jobManager.retryAllFailedJobs()
        XCTAssertEqual(retried.count, 2)
        XCTAssertTrue(jobManager.failedJobs.isEmpty)
    }

    func testConcurrencyThrottlingLimits() {
        jobManager.updateMaxConcurrency(1)
        XCTAssertEqual(jobManager.maxConcurrency, 1)

        jobManager.updateMaxConcurrency(4)
        XCTAssertEqual(jobManager.maxConcurrency, 4)

        // Check clamping bounds
        jobManager.updateMaxConcurrency(0)
        XCTAssertEqual(jobManager.maxConcurrency, 1)

        jobManager.updateMaxConcurrency(99)
        XCTAssertEqual(jobManager.maxConcurrency, 8)
    }
}
