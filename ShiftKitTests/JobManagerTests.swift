import XCTest
@testable import ShiftKit

final class JobManagerTests: XCTestCase {
    private var jobManager: JobManager!

    override func setUp() {
        super.setUp()
        jobManager = JobManager()
    }

    func testJobEnqueueing() {
        let req = ConversionRequest(
            sourceURL: URL(fileURLWithPath: "/tmp/sample.png"),
            fileType: .image(.png),
            action: .imageToJPEG
        )

        let job = jobManager.enqueue(request: req)
        XCTAssertEqual(job.sourceFileName, "sample.png")
        XCTAssertEqual(job.actionTitle, "To JPEG")
        XCTAssertFalse(jobManager.activeJobs.isEmpty)
    }

    func testClearCompleted() {
        jobManager.populateSampleJobsForPreview()
        XCTAssertFalse(jobManager.completedJobs.isEmpty)

        jobManager.clearCompletedJobs()
        XCTAssertTrue(jobManager.completedJobs.isEmpty)
    }
}
