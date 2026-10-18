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
}
