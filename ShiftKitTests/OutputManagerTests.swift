import XCTest
@testable import ShiftKit

final class OutputManagerTests: XCTestCase {
    private var manager: OutputManager!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        manager = OutputManager()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testResolveDestinationURLWithoutCollision() {
        let source = URL(fileURLWithPath: "/path/to/image.png")
        let destination = manager.resolveDestinationURL(
            for: source,
            targetExtension: "webp",
            suffix: "converted",
            customDirectory: tempDir
        )

        XCTAssertEqual(destination.deletingLastPathComponent().path, tempDir.path)
        XCTAssertEqual(destination.lastPathComponent, "image_converted.webp")
    }

    func testResolveDestinationURLWithCollision() {
        let source = URL(fileURLWithPath: "/path/to/document.pdf")
        let firstDest = tempDir.appendingPathComponent("document_compress.pdf")
        FileManager.default.createFile(atPath: firstDest.path, contents: Data())

        let secondDest = manager.resolveDestinationURL(
            for: source,
            targetExtension: "pdf",
            suffix: "compress",
            customDirectory: tempDir
        )

        XCTAssertEqual(secondDest.lastPathComponent, "document_compress_1.pdf")
    }

    func testBesideOriginalStrategy() async throws {
        let original = tempDir.appendingPathComponent("sample.png")
        FileManager.default.createFile(atPath: original.path, contents: Data())

        let dest = try await manager.resolveDestinationURL(
            for: original,
            targetExtension: "jpeg",
            suffix: "converted",
            strategy: .besideOriginal
        )

        XCTAssertEqual(dest.deletingLastPathComponent().path, tempDir.path)
        XCTAssertEqual(dest.lastPathComponent, "sample_converted.jpeg")
    }

    func testDedicatedFolderStrategy() async throws {
        let dedicatedDir = tempDir.appendingPathComponent("DedicatedOutputs")
        let original = tempDir.appendingPathComponent("photo.jpg")

        let dest = try await manager.resolveDestinationURL(
            for: original,
            targetExtension: "webp",
            suffix: nil,
            strategy: .dedicatedFolder(dedicatedDir)
        )

        XCTAssertEqual(dest.deletingLastPathComponent().path, dedicatedDir.path)
        XCTAssertEqual(dest.lastPathComponent, "photo.webp")
        XCTAssertTrue(FileManager.default.fileExists(atPath: dedicatedDir.path))
    }

    func testTemporaryOutputLifecycleAndCommit() throws {
        let dest = tempDir.appendingPathComponent("output.png")
        let tempURL = try manager.createTemporaryOutputURL(for: dest)

        XCTAssertTrue(tempURL.lastPathComponent.contains(".tmp-"))

        // Simulate engine writing to temp
        let testData = "ShiftKit Output Content".data(using: .utf8)!
        try testData.write(to: tempURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))

        // Commit atomically
        try manager.commitTemporaryOutput(temporaryURL: tempURL, destinationURL: dest)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dest.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempURL.path))

        let readData = try Data(contentsOf: dest)
        XCTAssertEqual(readData, testData)
    }

    func testTemporaryOutputCleanupOnFailure() throws {
        let dest = tempDir.appendingPathComponent("aborted.png")
        let tempURL = try manager.createTemporaryOutputURL(for: dest)

        try "Aborted Data".data(using: .utf8)!.write(to: tempURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))

        // Cleanup
        manager.cleanupTemporaryOutput(temporaryURL: tempURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: dest.path))
    }

    func testOutputNameConflictDetection() {
        let source1 = URL(fileURLWithPath: "/dir1/image.png")
        let source2 = URL(fileURLWithPath: "/dir2/image.png")
        let source3 = URL(fileURLWithPath: "/dir3/other.png")

        let conflicts = manager.detectConflicts(
            sources: [source1, source2, source3],
            targetExtension: "webp",
            suffix: "out",
            targetDirectory: tempDir
        )

        XCTAssertEqual(conflicts.count, 1)
        let conflictList = conflicts.values.first ?? []
        XCTAssertEqual(conflictList.count, 2)
        XCTAssertTrue(conflictList.contains(source1))
        XCTAssertTrue(conflictList.contains(source2))
    }
}
