import XCTest
@testable import ShiftKit

final class ConversionRouterTests: XCTestCase {
    private var router: ConversionRouter!

    override func setUp() {
        super.setUp()
        router = ConversionRouter()
    }

    func testImageRouting() throws {
        let request = ConversionRequest(
            sourceURL: URL(fileURLWithPath: "/tmp/test.png"),
            fileType: .image(.png),
            action: .imageToJPEG
        )
        let engine = try router.route(request: request)
        XCTAssertEqual(engine.engineID, "com.shiftkit.engine.imageio")
    }

    func testPDFRouting() throws {
        let request = ConversionRequest(
            sourceURL: URL(fileURLWithPath: "/tmp/doc.pdf"),
            fileType: .pdf,
            action: .pdfCompress
        )
        let engine = try router.route(request: request)
        XCTAssertEqual(engine.engineID, "com.shiftkit.engine.pdfkit")
    }

    func testAVFoundationRouting() throws {
        let request = ConversionRequest(
            sourceURL: URL(fileURLWithPath: "/tmp/clip.mov"),
            fileType: .video(.mov),
            action: .videoCompress
        )
        let engine = try router.route(request: request)
        XCTAssertEqual(engine.engineID, "com.shiftkit.engine.avfoundation")
    }

    func testFFmpegRouting() throws {
        let request = ConversionRequest(
            sourceURL: URL(fileURLWithPath: "/tmp/clip.mp4"),
            fileType: .video(.mp4),
            action: .videoToGIF
        )
        let engine = try router.route(request: request)
        XCTAssertEqual(engine.engineID, "com.shiftkit.engine.ffmpeg")
    }

    func testDestinationResolution() {
        let request = ConversionRequest(
            sourceURL: URL(fileURLWithPath: "/tmp/photo.png"),
            fileType: .image(.png),
            action: .imageToWebP
        )
        let destination = router.resolveDestination(for: request)
        XCTAssertEqual(destination.pathExtension, "webp")
        XCTAssertTrue(destination.lastPathComponent.contains("photo"))
    }

    func testUnsupportedConversionValidation() {
        let textFile = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/notes.txt"),
            fileType: .document(.txt),
            metadata: FileMetadata(fileSize: 100, fileExtension: "txt")
        )
        // Converting plain text to MP4 video is not supported
        let result = router.validate(source: textFile, targetFormat: .mp4)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorReason)
    }

    func testLossyToLosslessContainerFidelityWarning() {
        let jpegFile = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/photo.jpg"),
            fileType: .image(.jpeg),
            metadata: FileMetadata(
                fileSize: 45000,
                fileExtension: "jpg",
                detectedFormat: .jpeg
            )
        )

        let result = router.validate(source: jpegFile, targetFormat: .png)
        XCTAssertTrue(result.isValid)
        XCTAssertFalse(result.isLossless, "Converting a lossy source container into a lossless container cannot be marked lossless")

        let hasWarning = result.warnings.contains { warning in
            if case .lossyToLosslessContainer = warning { return true }
            return false
        }
        XCTAssertTrue(hasWarning, "Router must generate a warning that lossy compression detail is not restored")
    }

    func testAlphaChannelDiscardedWarning() {
        let pngWithAlpha = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/logo.png"),
            fileType: .image(.png),
            metadata: FileMetadata(
                fileSize: 12000,
                fileExtension: "png",
                hasAlphaChannel: true,
                detectedFormat: .png
            )
        )

        let result = router.validate(source: pngWithAlpha, targetFormat: .jpeg)
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.warnings.contains(.alphaChannelDiscarded))
        XCTAssertTrue(result.discardedFeatures.contains(where: { $0.lowercased().contains("alpha") }))
    }

    func testFormatExtensionMismatchWarning() {
        let mismatchedFile = InspectedFile(
            url: URL(fileURLWithPath: "/tmp/image.png"),
            fileType: .image(.jpeg),
            metadata: FileMetadata(
                fileSize: 30000,
                fileExtension: "png",
                isFormatExtensionMismatch: true,
                detectedFormat: .jpeg
            )
        )

        let result = router.validate(source: mismatchedFile, targetFormat: .webp)
        XCTAssertTrue(result.isValid)
        let hasMismatchWarning = result.warnings.contains { warning in
            if case .extensionMismatch = warning { return true }
            return false
        }
        XCTAssertTrue(hasMismatchWarning)
    }
}
