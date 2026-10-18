import XCTest
@testable import ShiftKit

final class JobHistoryStoreTests: XCTestCase {
    private var tempDir: URL!
    private var historyFile: URL!
    private var store: JobHistoryStore!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        historyFile = tempDir.appendingPathComponent("history.json")
        store = JobHistoryStore(customFileURL: historyFile)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testRecordCompletedJob() {
        let inputURL = URL(fileURLWithPath: "/Users/test/Documents/vacation.png")
        let outputURL = URL(fileURLWithPath: "/Users/test/Documents/vacation.webp")
        var job = ConversionJob(
            inputs: [inputURL],
            operation: .imageToWebP,
            outputFormat: .webp,
            destinationURL: outputURL
        )
        job.completedAt = Date()
        job.status = .completed(outputURL: outputURL, duration: 1.25, outputSize: 45_000)

        store.record(job: job)

        XCTAssertEqual(store.items.count, 1)
        let item = store.items.first!
        XCTAssertEqual(item.id, job.id)
        XCTAssertEqual(item.filename, "vacation.png")
        XCTAssertEqual(item.operationTitle, "To WebP")
        XCTAssertEqual(item.status, "completed")
        XCTAssertEqual(item.outputURL, outputURL)
        XCTAssertEqual(item.outputSize, 45_000)
        XCTAssertTrue(item.isSuccess)
    }

    func testRecordFailedJob() {
        let inputURL = URL(fileURLWithPath: "/Users/test/Documents/corrupt.mp4")
        var job = ConversionJob(
            inputs: [inputURL],
            operation: .videoToMP4,
            outputFormat: .mp4
        )
        job.completedAt = Date()
        job.status = .failed(error: ShiftKitError.corruptMedia(reason: "Header invalid"))

        store.record(job: job)

        XCTAssertEqual(store.items.count, 1)
        let item = store.items.first!
        XCTAssertEqual(item.status, "failed")
        XCTAssertNil(item.outputURL)
        XCTAssertTrue(item.isFailed)
        XCTAssertNotNil(item.errorMessage)
        XCTAssertTrue(item.errorMessage?.contains("Header invalid") == true)
    }

    func testHistoryTrimmingToMaximumCount() {
        let inputURL = URL(fileURLWithPath: "/tmp/sample.png")
        for i in 1...110 {
            var job = ConversionJob(
                inputs: [inputURL],
                operation: .imageToPNG,
                outputFormat: .png
            )
            job.status = .completed(outputURL: inputURL, duration: 0.1, outputSize: Int64(i * 100))
            store.record(job: job)
        }

        XCTAssertEqual(store.items.count, 100)
    }

    func testClearHistory() {
        let inputURL = URL(fileURLWithPath: "/tmp/sample.png")
        var job = ConversionJob(
            inputs: [inputURL],
            operation: .imageToPNG,
            outputFormat: .png
        )
        job.status = .completed(outputURL: inputURL, duration: 0.1, outputSize: 1000)
        store.record(job: job)
        XCTAssertEqual(store.items.count, 1)

        store.clearHistory()
        XCTAssertTrue(store.items.isEmpty)
    }
}
