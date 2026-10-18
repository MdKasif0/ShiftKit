import XCTest
@testable import ShiftKit

final class MultiFileValidationTests: XCTestCase {
    private var registry: ConversionRegistry!
    private var outputManager: OutputManager!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        registry = ConversionRegistry()
        outputManager = OutputManager()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testBatchConversionWithMixedSelection() {
        let png1 = InspectedFile(
            url: URL(fileURLWithPath: "/path/a/shot1.png"),
            fileType: .image(.png),
            metadata: FileMetadata(fileSize: 1000, fileExtension: "png")
        )
        let png2 = InspectedFile(
            url: URL(fileURLWithPath: "/path/b/shot2.png"),
            fileType: .image(.png),
            metadata: FileMetadata(fileSize: 2000, fileExtension: "png")
        )
        let docx = InspectedFile(
            url: URL(fileURLWithPath: "/path/c/notes.docx"),
            fileType: .document(.docx),
            metadata: FileMetadata(fileSize: 5000, fileExtension: "docx")
        )

        let batchResult = registry.validateBatch(files: [png1, png2, docx], targetFormat: .jpeg)

        XCTAssertFalse(batchResult.allCompatible, "Mixed batch containing docx cannot be marked allCompatible for JPEG conversion")
        XCTAssertEqual(batchResult.supportedFiles.count, 2)
        XCTAssertEqual(batchResult.unsupportedFiles.count, 1)

        let unsupported = batchResult.unsupportedFiles.first!
        XCTAssertEqual(unsupported.file.url, docx.url)
        XCTAssertTrue(unsupported.reason.contains("docx") || unsupported.reason.contains("Document"))
    }

    func testBatchConversionOutputConflictDetection() {
        let file1 = InspectedFile(
            url: URL(fileURLWithPath: "/folderA/receipt.pdf"),
            fileType: .pdf,
            metadata: FileMetadata(fileSize: 12000, fileExtension: "pdf")
        )
        let file2 = InspectedFile(
            url: URL(fileURLWithPath: "/folderB/receipt.pdf"),
            fileType: .pdf,
            metadata: FileMetadata(fileSize: 15000, fileExtension: "pdf")
        )

        let batchResult = registry.validateBatch(files: [file1, file2], targetFormat: .png)

        XCTAssertFalse(batchResult.allCompatible, "Identical output target names in batch must be flagged as conflict")
        XCTAssertFalse(batchResult.outputNameConflicts.isEmpty)
    }

    func testMergeCompatiblePDFSelection() {
        let pdf1 = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/chapter1.pdf"),
            fileType: .pdf,
            metadata: FileMetadata(fileSize: 20000, fileExtension: "pdf")
        )
        let pdf2 = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/chapter2.pdf"),
            fileType: .pdf,
            metadata: FileMetadata(fileSize: 25000, fileExtension: "pdf")
        )
        let img = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/diagram.png"),
            fileType: .image(.png),
            metadata: FileMetadata(fileSize: 8000, fileExtension: "png")
        )

        let mergeResult = registry.validateMerge(files: [pdf1, pdf2, img], targetFormat: .pdf)
        XCTAssertTrue(mergeResult.canMerge, "PDFs and images can be merged together into a PDF document")
        XCTAssertEqual(mergeResult.compatibleFiles.count, 3)
        XCTAssertTrue(mergeResult.incompatibleFiles.isEmpty)
    }

    func testMergeIncompatibleMediaStreams() {
        let pdf = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/contract.pdf"),
            fileType: .pdf,
            metadata: FileMetadata(fileSize: 10000, fileExtension: "pdf")
        )
        let song = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/soundtrack.mp3"),
            fileType: .audio(.mp3),
            metadata: FileMetadata(fileSize: 800000, fileExtension: "mp3")
        )

        let mergeResult = registry.validateMerge(files: [pdf, song], targetFormat: .pdf)
        XCTAssertFalse(mergeResult.canMerge, "Cannot merge PDF with MP3 audio stream")
        XCTAssertEqual(mergeResult.incompatibleFiles.count, 1)
        XCTAssertNotNil(mergeResult.failureReason)
    }
}
