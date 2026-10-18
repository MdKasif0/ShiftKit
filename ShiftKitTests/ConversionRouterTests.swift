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
}
