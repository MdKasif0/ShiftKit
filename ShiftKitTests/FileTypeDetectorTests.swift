import XCTest
@testable import ShiftKit

final class FileTypeDetectorTests: XCTestCase {
    private var detector: FileTypeDetector!
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        detector = FileTypeDetector()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testImageDetection() {
        let pngURL = URL(fileURLWithPath: "/tmp/sample.png")
        XCTAssertEqual(detector.detectType(for: pngURL), .image(.png))

        let jpgURL = URL(fileURLWithPath: "/tmp/photo.jpg")
        XCTAssertEqual(detector.detectType(for: jpgURL), .image(.jpeg))

        let webpURL = URL(fileURLWithPath: "/tmp/graphic.webp")
        XCTAssertEqual(detector.detectType(for: webpURL), .image(.webp))

        let heicURL = URL(fileURLWithPath: "/tmp/shot.heic")
        XCTAssertEqual(detector.detectType(for: heicURL), .image(.heic))
    }

    func testVideoDetection() {
        let mp4URL = URL(fileURLWithPath: "/tmp/clip.mp4")
        XCTAssertEqual(detector.detectType(for: mp4URL), .video(.mp4))

        let movURL = URL(fileURLWithPath: "/tmp/movie.mov")
        XCTAssertEqual(detector.detectType(for: movURL), .video(.mov))
    }

    func testAudioDetection() {
        let mp3URL = URL(fileURLWithPath: "/tmp/song.mp3")
        XCTAssertEqual(detector.detectType(for: mp3URL), .audio(.mp3))

        let wavURL = URL(fileURLWithPath: "/tmp/recording.wav")
        XCTAssertEqual(detector.detectType(for: wavURL), .audio(.wav))
    }

    func testPDFDetection() {
        let pdfURL = URL(fileURLWithPath: "/tmp/document.pdf")
        XCTAssertEqual(detector.detectType(for: pdfURL), .pdf)
    }

    func testArchiveDetection() {
        let zipURL = URL(fileURLWithPath: "/tmp/bundle.zip")
        XCTAssertEqual(detector.detectType(for: zipURL), .archive)
    }

    func testUnknownDetection() {
        let xyzURL = URL(fileURLWithPath: "/tmp/data.xyz123")
        XCTAssertEqual(detector.detectType(for: xyzURL), .unknown(extensionName: "xyz123"))
    }

    func testMagicHeaderSniffing() {
        // PNG header
        let pngBytes: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00]
        XCTAssertEqual(detector.sniffHeader(data: Data(pngBytes)), .png)

        // JPEG header
        let jpegBytes: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]
        XCTAssertEqual(detector.sniffHeader(data: Data(jpegBytes)), .jpeg)

        // GIF header
        let gifBytes: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61] // GIF89a
        XCTAssertEqual(detector.sniffHeader(data: Data(gifBytes)), .gif)

        // WebP header (RIFF....WEBP)
        var webpBytes: [UInt8] = [0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50]
        XCTAssertEqual(detector.sniffHeader(data: Data(webpBytes)), .webp)

        // PDF header
        let pdfBytes: [UInt8] = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37]
        XCTAssertEqual(detector.sniffHeader(data: Data(pdfBytes)), .pdf)

        // ZIP header
        let zipBytes: [UInt8] = [0x50, 0x4B, 0x03, 0x04, 0x14, 0x00]
        XCTAssertEqual(detector.sniffHeader(data: Data(zipBytes)), .zip)

        // Random unrecognized bytes
        let unknownBytes: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05]
        XCTAssertNil(detector.sniffHeader(data: Data(unknownBytes)))
    }

    func testExtensionMismatchDetectionOnDisk() throws {
        // Create a file named "fake.png" that actually contains JPEG magic bytes
        let fileURL = tempDirectory.appendingPathComponent("fake.png")
        let jpegBytes: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46]
        try Data(jpegBytes).write(to: fileURL)

        let mismatch = detector.checkFormatMismatch(for: fileURL)
        XCTAssertTrue(mismatch.hasMismatch, "Detector must flag mismatch between declared .png and actual JPEG data")
        XCTAssertEqual(mismatch.actualFormat, .jpeg)
        XCTAssertEqual(mismatch.declaredExtension, "png")

        // Detecting type directly should resolve to JPEG based on inspection
        let resolvedType = detector.detectType(for: fileURL)
        XCTAssertEqual(resolvedType, .image(.jpeg))
    }
}
