import XCTest
@testable import ShiftKit

final class ConversionRegistryTests: XCTestCase {
    private var registry: ConversionRegistry!

    override func setUp() {
        super.setUp()
        registry = ConversionRegistry()
    }

    func testImageActions() {
        let pngActions = registry.actions(for: .image(.png))
        XCTAssertFalse(pngActions.isEmpty)
        XCTAssertTrue(pngActions.contains(where: { $0.id == "img_to_jpeg" }))
        XCTAssertTrue(pngActions.contains(where: { $0.id == "img_to_webp" }))
        XCTAssertTrue(pngActions.contains(where: { $0.id == "img_compress" }))
        XCTAssertTrue(pngActions.contains(where: { $0.id == "img_crop_square" }))
        XCTAssertTrue(pngActions.contains(where: { $0.id == "img_strip_exif" }))

        let jpegActions = registry.actions(for: .image(.jpeg))
        XCTAssertTrue(jpegActions.contains(where: { $0.id == "img_to_png" }))
    }

    func testVideoActions() {
        let videoActions = registry.actions(for: .video(.mp4))
        XCTAssertFalse(videoActions.isEmpty)
        XCTAssertTrue(videoActions.contains(where: { $0.id == "vid_to_mp4" }))
        XCTAssertTrue(videoActions.contains(where: { $0.id == "vid_to_gif" }))
        XCTAssertTrue(videoActions.contains(where: { $0.id == "vid_extract_audio" }))
        XCTAssertTrue(videoActions.contains(where: { $0.id == "vid_compress" }))
        XCTAssertTrue(videoActions.contains(where: { $0.id == "vid_trim" }))
    }

    func testAudioActions() {
        let audioActions = registry.actions(for: .audio(.wav))
        XCTAssertFalse(audioActions.isEmpty)
        XCTAssertTrue(audioActions.contains(where: { $0.id == "audio_to_mp3" }))
        XCTAssertTrue(audioActions.contains(where: { $0.id == "audio_to_m4a" }))
        XCTAssertTrue(audioActions.contains(where: { $0.id == "audio_compress" }))
    }

    func testPDFActions() {
        let pdfActions = registry.actions(for: .pdf)
        XCTAssertFalse(pdfActions.isEmpty)
        XCTAssertTrue(pdfActions.contains(where: { $0.id == "pdf_compress" }))
        XCTAssertTrue(pdfActions.contains(where: { $0.id == "pdf_to_images" }))
        XCTAssertTrue(pdfActions.contains(where: { $0.id == "pdf_merge" }))
    }

    func testRegistryIntegrityAndCapabilityValidation() {
        let allCaps = registry.registeredCapabilities()
        XCTAssertFalse(allCaps.isEmpty)

        for cap in allCaps {
            XCTAssertFalse(cap.id.isEmpty, "Capability ID must not be empty")
            XCTAssertFalse(cap.displayName.isEmpty, "Capability displayName must not be empty")
            XCTAssertFalse(cap.requiredEngineID.isEmpty, "Capability requiredEngineID must not be empty")
            XCTAssertNotNil(cap.sourceFormat, "Source format \(cap.sourceFormatID) must resolve to canonical OutputFormat")
            XCTAssertNotNil(cap.targetFormat, "Target format \(cap.targetFormatID) must resolve to canonical OutputFormat")
        }
    }

    func testImplementedVsPlannedCapabilities() {
        let implemented = registry.implementedCapabilities()
        let all = registry.registeredCapabilities()

        XCTAssertTrue(implemented.count < all.count, "Planned capabilities should exist alongside implemented capabilities")
        XCTAssertTrue(implemented.allSatisfy { $0.isImplemented })

        // Verify planned capabilities are not marked implemented
        let docCap = all.first { $0.id == "doc_to_pdf" }
        XCTAssertNotNil(docCap)
        XCTAssertFalse(docCap?.isImplemented ?? true, "Planned pandoc capability must not be marked implemented")

        let zipCap = all.first { $0.id == "zip_extract" }
        XCTAssertNotNil(zipCap)
        XCTAssertFalse(zipCap?.isImplemented ?? true, "Planned archive extraction must not be marked implemented")
    }

    func testBatchValidationCompatible() {
        let file1 = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/photo1.png"),
            fileType: .image(.png),
            metadata: FileMetadata(fileSize: 1024, fileExtension: "png")
        )
        let file2 = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/photo2.png"),
            fileType: .image(.png),
            metadata: FileMetadata(fileSize: 2048, fileExtension: "png")
        )

        let result = registry.validateBatch(files: [file1, file2], targetFormat: .webp)
        XCTAssertTrue(result.allCompatible)
        XCTAssertEqual(result.supportedFiles.count, 2)
        XCTAssertTrue(result.unsupportedFiles.isEmpty)
    }

    func testBatchValidationMixedSelection() {
        let imageFile = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/image.png"),
            fileType: .image(.png),
            metadata: FileMetadata(fileSize: 1024, fileExtension: "png")
        )
        let archiveFile = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/data.zip"),
            fileType: .archive,
            metadata: FileMetadata(fileSize: 5000, fileExtension: "zip")
        )

        let result = registry.validateBatch(files: [imageFile, archiveFile], targetFormat: .webp)
        XCTAssertFalse(result.allCompatible)
        XCTAssertEqual(result.supportedFiles.count, 1)
        XCTAssertEqual(result.unsupportedFiles.count, 1)
        XCTAssertEqual(result.unsupportedFiles.first?.file.url, archiveFile.url)
    }

    func testMergeValidationPDFsCompatible() {
        let doc1 = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/doc1.pdf"),
            fileType: .pdf,
            metadata: FileMetadata(fileSize: 5000, fileExtension: "pdf")
        )
        let doc2 = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/doc2.pdf"),
            fileType: .pdf,
            metadata: FileMetadata(fileSize: 8000, fileExtension: "pdf")
        )

        let result = registry.validateMerge(files: [doc1, doc2], targetFormat: .pdf)
        XCTAssertTrue(result.canMerge)
        XCTAssertEqual(result.compatibleFiles.count, 2)
        XCTAssertNil(result.failureReason)
    }

    func testMergeValidationIncompatibleMixed() {
        let pdf = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/doc.pdf"),
            fileType: .pdf,
            metadata: FileMetadata(fileSize: 5000, fileExtension: "pdf")
        )
        let video = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/movie.mp4"),
            fileType: .video(.mp4),
            metadata: FileMetadata(fileSize: 150000, fileExtension: "mp4")
        )

        let result = registry.validateMerge(files: [pdf, video], targetFormat: .pdf)
        XCTAssertFalse(result.canMerge)
        XCTAssertNotNil(result.failureReason)
        XCTAssertEqual(result.incompatibleFiles.count, 1)
    }
}
