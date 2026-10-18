import XCTest
@testable import ShiftKit

final class OutputConflictAndValidationTests: XCTestCase {
    private var tempDir: URL!
    private var outputManager: OutputManager!

    override func setUp() {
        super.setUp()
        outputManager = OutputManager()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Conflict Resolution: Rename with Number

    func testConflictResolutionRenameWithNumber() throws {
        let sourceURL = tempDir.appendingPathComponent("document.pdf")
        let existingDest = tempDir.appendingPathComponent("document.pdf")
        FileManager.default.createFile(atPath: existingDest.path, contents: "existing".data(using: .utf8))

        let resolved = try outputManager.resolveDestination(
            for: sourceURL,
            targetExtension: "pdf",
            suffix: nil,
            customDirectory: tempDir,
            conflictResolution: .renameWithNumber
        )

        XCTAssertEqual(resolved.lastPathComponent, "document_1.pdf")
    }

    func testConflictResolutionMultipleNumberedCollisions() throws {
        let sourceURL = tempDir.appendingPathComponent("photo.png")
        FileManager.default.createFile(atPath: tempDir.appendingPathComponent("photo.png").path, contents: "0".data(using: .utf8))
        FileManager.default.createFile(atPath: tempDir.appendingPathComponent("photo_1.png").path, contents: "1".data(using: .utf8))
        FileManager.default.createFile(atPath: tempDir.appendingPathComponent("photo_2.png").path, contents: "2".data(using: .utf8))

        let resolved = try outputManager.resolveDestination(
            for: sourceURL,
            targetExtension: "png",
            suffix: nil,
            customDirectory: tempDir,
            conflictResolution: .renameWithNumber
        )

        XCTAssertEqual(resolved.lastPathComponent, "photo_3.png")
    }

    // MARK: - Conflict Resolution: Overwrite

    func testConflictResolutionOverwrite() throws {
        let sourceURL = tempDir.appendingPathComponent("data.csv")
        let existingDest = tempDir.appendingPathComponent("data.csv")
        FileManager.default.createFile(atPath: existingDest.path, contents: "first".data(using: .utf8))

        let resolved = try outputManager.resolveDestination(
            for: sourceURL,
            targetExtension: "csv",
            suffix: nil,
            customDirectory: tempDir,
            conflictResolution: .overwrite
        )

        XCTAssertEqual(resolved.path, existingDest.path)
    }

    // MARK: - Conflict Resolution: Fail with Conflict

    func testConflictResolutionFailWithConflict() {
        let sourceURL = tempDir.appendingPathComponent("report.pdf")
        let existingDest = tempDir.appendingPathComponent("report.pdf")
        FileManager.default.createFile(atPath: existingDest.path, contents: "content".data(using: .utf8))

        XCTAssertThrowsError(
            try outputManager.resolveDestination(
                for: sourceURL,
                targetExtension: "pdf",
                suffix: nil,
                customDirectory: tempDir,
                conflictResolution: .failWithConflict
            )
        ) { error in
            guard case ShiftKitError.outputConflict(let conflictedURL) = error else {
                XCTFail("Expected ShiftKitError.outputConflict, got \(error)")
                return
            }
            XCTAssertEqual(conflictedURL.path, existingDest.path)
        }
    }

    // MARK: - Output Validation

    func testValidateOutputSucceedsOnValidFile() throws {
        let testFile = tempDir.appendingPathComponent("valid.txt")
        let testData = "Hello World".data(using: .utf8)!
        FileManager.default.createFile(atPath: testFile.path, contents: testData)

        let size = try outputManager.validateOutput(at: testFile)
        XCTAssertEqual(size, Int64(testData.count))
    }

    func testValidateOutputFailsOnNonexistentFile() {
        let nonExistent = tempDir.appendingPathComponent("does_not_exist.txt")
        XCTAssertThrowsError(try outputManager.validateOutput(at: nonExistent))
    }

    func testValidateOutputFailsOnZeroByteFile() {
        let emptyFile = tempDir.appendingPathComponent("empty.txt")
        FileManager.default.createFile(atPath: emptyFile.path, contents: Data())

        XCTAssertThrowsError(try outputManager.validateOutput(at: emptyFile))
    }
}
