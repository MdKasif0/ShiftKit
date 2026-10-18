import XCTest
@testable import ShiftKit

final class BatchOperationsTests: XCTestCase {
    private var tempDir: URL!
    private var outputManager: OutputManager!
    private var historyStore: JobHistoryStore!
    private var jobManager: JobManager!

    override func setUp() async throws {
        try await super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let historyURL = tempDir.appendingPathComponent("batch_history.json")
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

    private func createTestPNG(named name: String) -> URL {
        let url = tempDir.appendingPathComponent(name)
        let image = NSImage(size: NSSize(width: 32, height: 32))
        image.lockFocus()
        NSColor.systemGreen.drawSwatch(in: NSRect(x: 0, y: 0, width: 32, height: 32))
        image.unlockFocus()
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            fatalError("Could not create test PNG")
        }
        try! png.write(to: url)
        return url
    }

    // MARK: - Multiple-File Conversion

    func testBatchMultipleFileConversion() async throws {
        let file1 = createTestPNG(named: "photo_1.png")
        let file2 = createTestPNG(named: "photo_2.png")
        let file3 = createTestPNG(named: "photo_3.png")

        let r1 = ConversionRequest(
            sourceURL: file1,
            fileType: .image(.png),
            action: .imageToJPEG,
            destinationURL: tempDir.appendingPathComponent("photo_1.jpg")
        )
        let r2 = ConversionRequest(
            sourceURL: file2,
            fileType: .image(.png),
            action: .imageToJPEG,
            destinationURL: tempDir.appendingPathComponent("photo_2.jpg")
        )
        let r3 = ConversionRequest(
            sourceURL: file3,
            fileType: .image(.png),
            action: .imageToJPEG,
            destinationURL: tempDir.appendingPathComponent("photo_3.jpg")
        )

        let jobs = jobManager.enqueueBatch(requests: [r1, r2, r3])
        XCTAssertEqual(jobs.count, 3)

        // Wait for all 3 to finish
        let deadline = Date().addingTimeInterval(8.0)
        var finishedCount = 0
        while Date() < deadline {
            let completedIDs = Set(jobManager.completedJobs.map { $0.id })
            finishedCount = jobs.filter { completedIDs.contains($0.id) }.count
            if finishedCount == 3 { break }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        XCTAssertEqual(finishedCount, 3)

        // Validate all output files exist on disk with positive size
        for job in jobs {
            guard let completed = jobManager.completedJobs.first(where: { $0.id == job.id }) else {
                XCTFail("Job \(job.id) missing in completedJobs")
                continue
            }
            if case .completed(let outURL, _, let size) = completed.status {
                XCTAssertTrue(FileManager.default.fileExists(atPath: outURL.path))
                XCTAssertGreaterThan(size, 0)
            } else {
                XCTFail("Expected completed status for job \(job.id), got \(completed.status)")
            }
        }
    }

    // MARK: - Partial Failure Isolation

    func testBatchPartialFailureIsolation() async throws {
        let valid1 = createTestPNG(named: "valid_1.png")
        let missing = tempDir.appendingPathComponent("missing_file.png")
        let valid2 = createTestPNG(named: "valid_2.png")

        let r1 = ConversionRequest(
            sourceURL: valid1,
            fileType: .image(.png),
            action: .imageToJPEG,
            destinationURL: tempDir.appendingPathComponent("valid_1.jpg")
        )
        let rFail = ConversionRequest(
            sourceURL: missing,
            fileType: .image(.png),
            action: .imageToJPEG,
            destinationURL: tempDir.appendingPathComponent("missing_file.jpg")
        )
        let r2 = ConversionRequest(
            sourceURL: valid2,
            fileType: .image(.png),
            action: .imageToJPEG,
            destinationURL: tempDir.appendingPathComponent("valid_2.jpg")
        )

        let jobs = jobManager.enqueueBatch(requests: [r1, rFail, r2])
        XCTAssertEqual(jobs.count, 3)

        // Wait for completion/failure of all 3
        let deadline = Date().addingTimeInterval(8.0)
        while Date() < deadline {
            let terminalCount = jobManager.completedJobs.count
            if terminalCount >= 3 { break }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        // Job 2 (missing) must be failed
        let failedJob = jobManager.completedJobs.first(where: { $0.id == jobs[1].id })
        XCTAssertNotNil(failedJob)
        if case .failed(let err) = failedJob?.status {
            XCTAssertTrue(err.localizedDescription.contains("missing_file.png") || err.localizedDescription.contains("find"))
        } else {
            XCTFail("Expected failed status for missing file job, got \(String(describing: failedJob?.status))")
        }

        // Jobs 1 and 3 must be successfully completed
        let completed1 = jobManager.completedJobs.first(where: { $0.id == jobs[0].id })
        let completed3 = jobManager.completedJobs.first(where: { $0.id == jobs[2].id })

        XCTAssertNotNil(completed1)
        XCTAssertNotNil(completed3)

        if case .completed(let out1, _, _) = completed1?.status {
            XCTAssertTrue(FileManager.default.fileExists(atPath: out1.path))
        } else {
            XCTFail("Job 1 should succeed despite Job 2 failure")
        }

        if case .completed(let out3, _, _) = completed3?.status {
            XCTAssertTrue(FileManager.default.fileExists(atPath: out3.path))
        } else {
            XCTFail("Job 3 should succeed despite Job 2 failure")
        }
    }

    // MARK: - Batch Cancellation

    func testBatchCancellation() async throws {
        let f1 = createTestPNG(named: "c1.png")
        let f2 = createTestPNG(named: "c2.png")
        let f3 = createTestPNG(named: "c3.png")

        let requests = [f1, f2, f3].map { url in
            ConversionRequest(
                sourceURL: url,
                fileType: .image(.png),
                action: .imageToJPEG,
                destinationURL: tempDir.appendingPathComponent("\(url.deletingPathExtension().lastPathComponent).jpg")
            )
        }

        let jobs = jobManager.enqueueBatch(requests: requests)
        let idsToCancel = [jobs[1].id, jobs[2].id]

        jobManager.cancelBatch(ids: idsToCancel)

        // Wait briefly for cancellation handling
        try await Task.sleep(nanoseconds: 100_000_000)

        // Cancelled jobs should either be in completedJobs as cancelled or marked cancelled
        for id in idsToCancel {
            let active = jobManager.activeJobs.first(where: { $0.id == id })
            let completed = jobManager.completedJobs.first(where: { $0.id == id })
            XCTAssertTrue(active?.isCancelled == true || active?.status == .cancelled || completed?.status == .cancelled)
        }
    }

    // MARK: - Batch Output Conflict Handling

    func testBatchOutputConflictNumberedResolution() throws {
        let f1 = tempDir.appendingPathComponent("image.png")
        let f2 = tempDir.appendingPathComponent("subfolder/image.png")
        try? FileManager.default.createDirectory(at: tempDir.appendingPathComponent("subfolder"), withIntermediateDirectories: true)

        let outDir = tempDir.appendingPathComponent("output")
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        // First destination
        let dest1 = try outputManager.resolveDestination(
            for: f1,
            targetExtension: "jpg",
            suffix: nil,
            customDirectory: outDir,
            conflictResolution: .renameWithNumber
        )
        // Simulate creation of dest1
        FileManager.default.createFile(atPath: dest1.path, contents: "test".data(using: .utf8))

        // Second destination for same basename
        let dest2 = try outputManager.resolveDestination(
            for: f2,
            targetExtension: "jpg",
            suffix: nil,
            customDirectory: outDir,
            conflictResolution: .renameWithNumber
        )

        XCTAssertNotEqual(dest1.path, dest2.path)
        XCTAssertEqual(dest1.lastPathComponent, "image.jpg")
        XCTAssertEqual(dest2.lastPathComponent, "image_1.jpg")
    }
}
