import XCTest
@testable import ShiftKit

final class FileTypeDetectorTests: XCTestCase {
    private var detector: FileTypeDetector!

    override func setUp() {
        super.setUp()
        detector = FileTypeDetector()
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
}
