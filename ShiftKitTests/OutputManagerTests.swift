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
}
