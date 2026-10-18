import XCTest
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import PDFKit
@testable import ShiftKit

final class ImageProcessingTests: XCTestCase {
    private var tempDir: URL!
    private var imageProcessor: ImageProcessor!
    private var detector: FileTypeDetector!

    override func setUp() {
        super.setUp()
        imageProcessor = ImageProcessor.shared
        detector = FileTypeDetector()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - 1. Crop Geometry & Clamping
    func testCropGeometryFreeformAndClamping() {
        let imageSize = CGSize(width: 800, height: 600)
        let engine = CropGeometryEngine(imageSize: imageSize, minCropDimension: 30)

        // Initial freeform rect
        let initial = engine.initialCropRect(for: .free)
        XCTAssertTrue(initial.origin.x >= 0 && initial.origin.y >= 0)
        XCTAssertTrue(initial.maxX <= imageSize.width && initial.maxY <= imageSize.height)

        // Move beyond bounds (should be clamped)
        let moved = engine.moveCropRect(initial, delta: CGPoint(x: 1000, y: 1000))
        XCTAssertEqual(moved.maxX, imageSize.width, accuracy: 0.1)
        XCTAssertEqual(moved.maxY, imageSize.height, accuracy: 0.1)

        let movedNegative = engine.moveCropRect(initial, delta: CGPoint(x: -1000, y: -1000))
        XCTAssertEqual(movedNegative.origin.x, 0.0, accuracy: 0.1)
        XCTAssertEqual(movedNegative.origin.y, 0.0, accuracy: 0.1)

        // Resize clamp check
        let resized = engine.resizeCropRect(initial, handle: .bottomRight, delta: CGPoint(x: 500, y: 500), preset: .free)
        XCTAssertTrue(resized.maxX <= imageSize.width)
        XCTAssertTrue(resized.maxY <= imageSize.height)
    }

    // MARK: - 2. Aspect Ratio Presets
    func testAspectRatioPreservation() {
        let imageSize = CGSize(width: 1920, height: 1080)
        let engine = CropGeometryEngine(imageSize: imageSize, minCropDimension: 20)

        // 1:1 Square
        let square = engine.initialCropRect(for: .square)
        XCTAssertEqual(square.width / square.height, 1.0, accuracy: 0.001)

        // 16:9 Landscape
        let wide = engine.initialCropRect(for: .landscape16_9)
        XCTAssertEqual(wide.width / wide.height, 16.0 / 9.0, accuracy: 0.001)

        // 9:16 Portrait
        let portrait = engine.initialCropRect(for: .portrait9_16)
        XCTAssertEqual(portrait.width / portrait.height, 9.0 / 16.0, accuracy: 0.001)

        // 4:3 Classic
        let fourThree = engine.initialCropRect(for: .landscape4_3)
        XCTAssertEqual(fourThree.width / fourThree.height, 4.0 / 3.0, accuracy: 0.001)

        // Aspect ratio resizing lock
        let resizedSquare = engine.resizeCropRect(square, handle: .bottomRight, delta: CGPoint(x: 80, y: 80), preset: .square)
        XCTAssertEqual(resizedSquare.width / resizedSquare.height, 1.0, accuracy: 0.001)
    }

    // MARK: - 3. PNG to JPEG with Alpha Flattening
    func testPNGToJPEGConversionAndAlphaFlattening() async throws {
        let pngURL = tempDir.appendingPathComponent("alpha_test.png")
        createSyntheticImage(at: pngURL, size: CGSize(width: 200, height: 200), hasAlpha: true)

        let jpegURL = tempDir.appendingPathComponent("alpha_test.jpg")
        let report = try await imageProcessor.process(
            sourceURL: pngURL,
            targetURL: jpegURL,
            targetFormat: .jpeg,
            options: ConversionOptions(quality: 0.85)
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: jpegURL.path))
        XCTAssertEqual(report.outputDimensions.width, 200)
        XCTAssertEqual(report.outputDimensions.height, 200)
        XCTAssertTrue(report.outputSizeBytes > 0)

        // Verify output is valid JPEG
        let detected = detector.detectActualFormat(for: jpegURL)
        XCTAssertEqual(detected, .jpeg)
    }

    // MARK: - 4. JPEG to WebP Conversion
    func testJPEGToWebPConversion() async throws {
        let jpgURL = tempDir.appendingPathComponent("sample.jpg")
        createSyntheticImage(at: jpgURL, size: CGSize(width: 300, height: 200), hasAlpha: false)

        let webpURL = tempDir.appendingPathComponent("sample.webp")
        let report = try await imageProcessor.process(
            sourceURL: jpgURL,
            targetURL: webpURL,
            targetFormat: .webp,
            options: ConversionOptions(quality: 0.80)
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: webpURL.path))
        XCTAssertTrue(report.outputSizeBytes > 0)

        // Verify WebP magic header
        let detected = detector.detectActualFormat(for: webpURL)
        XCTAssertEqual(detected, .webp)
    }

    // MARK: - 5. WebP to PNG Conversion
    func testWebPToPNGConversion() async throws {
        // First make a WebP
        let jpgURL = tempDir.appendingPathComponent("for_webp.jpg")
        createSyntheticImage(at: jpgURL, size: CGSize(width: 150, height: 150), hasAlpha: false)
        let webpURL = tempDir.appendingPathComponent("for_webp.webp")
        _ = try await imageProcessor.process(sourceURL: jpgURL, targetURL: webpURL, targetFormat: .webp)

        // Convert WebP -> PNG
        let pngOutURL = tempDir.appendingPathComponent("from_webp.png")
        let report = try await imageProcessor.process(
            sourceURL: webpURL,
            targetURL: pngOutURL,
            targetFormat: .png
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: pngOutURL.path))
        XCTAssertEqual(report.outputDimensions.width, 150)
        XCTAssertEqual(report.outputDimensions.height, 150)

        let detected = detector.detectActualFormat(for: pngOutURL)
        XCTAssertEqual(detected, .png)
    }

    // MARK: - 6. Image to PDF Export
    func testImageToPDFConversion() async throws {
        let imgURL = tempDir.appendingPathComponent("document_scan.png")
        createSyntheticImage(at: imgURL, size: CGSize(width: 400, height: 600), hasAlpha: false)

        let pdfURL = tempDir.appendingPathComponent("document_scan.pdf")
        let report = try await imageProcessor.process(
            sourceURL: imgURL,
            targetURL: pdfURL,
            targetFormat: .pdf
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: pdfURL.path))
        XCTAssertTrue(report.outputSizeBytes > 0)

        let pdfDoc = PDFDocument(url: pdfURL)
        XCTAssertNotNil(pdfDoc)
        XCTAssertEqual(pdfDoc?.pageCount, 1)
    }

    // MARK: - 7. Cropping and Resizing Operations
    func testCroppingAndResizingOperations() async throws {
        let imgURL = tempDir.appendingPathComponent("photo_hd.png")
        createSyntheticImage(at: imgURL, size: CGSize(width: 1000, height: 800), hasAlpha: false)

        // Crop center 400x400
        let cropRect = CGRect(x: 300, y: 200, width: 400, height: 400)
        let croppedURL = tempDir.appendingPathComponent("photo_cropped.png")

        let report = try await imageProcessor.process(
            sourceURL: imgURL,
            targetURL: croppedURL,
            targetFormat: .png,
            cropRect: cropRect
        )

        XCTAssertEqual(report.outputDimensions.width, 400)
        XCTAssertEqual(report.outputDimensions.height, 400)

        // Resize with max dimension constraint
        let resizedURL = tempDir.appendingPathComponent("photo_resized.png")
        let resizeReport = try await imageProcessor.process(
            sourceURL: imgURL,
            targetURL: resizedURL,
            targetFormat: .png,
            options: ConversionOptions(maxDimension: 500)
        )

        XCTAssertEqual(resizeReport.outputDimensions.width, 500)
        XCTAssertEqual(resizeReport.outputDimensions.height, 400) // 1000x800 -> 500x400
    }

    // MARK: - 8. Metadata Stripping
    func testMetadataStrippingOption() async throws {
        let imgURL = tempDir.appendingPathComponent("with_meta.jpg")
        createSyntheticImage(at: imgURL, size: CGSize(width: 200, height: 200), hasAlpha: false)

        let strippedURL = tempDir.appendingPathComponent("stripped.jpg")
        let report = try await imageProcessor.process(
            sourceURL: imgURL,
            targetURL: strippedURL,
            targetFormat: .jpeg,
            options: ConversionOptions(stripMetadata: true)
        )

        XCTAssertTrue(report.strippedMetadata)
        XCTAssertTrue(FileManager.default.fileExists(atPath: strippedURL.path))
    }

    // MARK: - 9. Large Image Processing Safety
    func testLargeImageProcessingSafety() async throws {
        let largeURL = tempDir.appendingPathComponent("large_panorama.png")
        createSyntheticImage(at: largeURL, size: CGSize(width: 2400, height: 1600), hasAlpha: false)

        let outputURL = tempDir.appendingPathComponent("large_result.jpg")
        let report = try await imageProcessor.process(
            sourceURL: largeURL,
            targetURL: outputURL,
            targetFormat: .jpeg,
            options: ConversionOptions(quality: 0.85)
        )

        XCTAssertEqual(report.outputDimensions.width, 2400)
        XCTAssertEqual(report.outputDimensions.height, 1600)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }

    // MARK: - 10. Unsupported Format Error Handling
    func testUnsupportedFormatErrorHandling() async {
        let nonExistentURL = tempDir.appendingPathComponent("does_not_exist.png")
        let outURL = tempDir.appendingPathComponent("fail.jpg")

        do {
            _ = try await imageProcessor.process(
                sourceURL: nonExistentURL,
                targetURL: outURL,
                targetFormat: .jpeg
            )
            XCTFail("Must throw fileNotFound error for missing file")
        } catch {
            XCTAssertFalse(FileManager.default.fileExists(atPath: outURL.path))
        }
    }

    // MARK: - 11. Percentage Scaling and Dimension Options
    func testPercentageScalingResizing() async throws {
        let imgURL = tempDir.appendingPathComponent("scale_test.png")
        createSyntheticImage(at: imgURL, size: CGSize(width: 600, height: 400), hasAlpha: false)

        let scaledURL = tempDir.appendingPathComponent("scale_test_half.png")
        let report = try await imageProcessor.process(
            sourceURL: imgURL,
            targetURL: scaledURL,
            targetFormat: .png,
            options: ConversionOptions(scaleMultiplier: 0.5)
        )

        XCTAssertEqual(report.outputDimensions.width, 300)
        XCTAssertEqual(report.outputDimensions.height, 200)
    }

    // MARK: - 12. Edge Handle Aspect Ratio Constraint
    func testEdgeHandleAspectRatioConstraints() {
        let imageSize = CGSize(width: 1000, height: 1000)
        let engine = CropGeometryEngine(imageSize: imageSize, minCropDimension: 40)
        let initial = engine.initialCropRect(for: .square)

        let resizedFromRight = engine.resizeCropRect(initial, handle: .right, delta: CGPoint(x: 100, y: 0), preset: .square)
        XCTAssertEqual(resizedFromRight.width / resizedFromRight.height, 1.0, accuracy: 0.001)

        let resizedFromBottom = engine.resizeCropRect(initial, handle: .bottom, delta: CGPoint(x: 0, y: -50), preset: .square)
        XCTAssertEqual(resizedFromBottom.width / resizedFromBottom.height, 1.0, accuracy: 0.001)
    }

    // MARK: - 13. TIFF Archival Conversion
    func testTIFFArchivalConversion() async throws {
        let pngURL = tempDir.appendingPathComponent("photo.png")
        createSyntheticImage(at: pngURL, size: CGSize(width: 250, height: 250), hasAlpha: true)

        let tiffURL = tempDir.appendingPathComponent("photo.tiff")
        let report = try await imageProcessor.process(
            sourceURL: pngURL,
            targetURL: tiffURL,
            targetFormat: .tiff
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: tiffURL.path))
        XCTAssertEqual(report.outputDimensions.width, 250)
        XCTAssertEqual(report.outputDimensions.height, 250)

        let detected = detector.detectActualFormat(for: tiffURL)
        XCTAssertEqual(detected, .tiff)
    }

    // MARK: - Helper Methods
    private func createSyntheticImage(at url: URL, size: CGSize, hasAlpha: Bool) {
        let w = Int(size.width)
        let h = Int(size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: UInt32 = hasAlpha
            ? CGImageAlphaInfo.premultipliedLast.rawValue
            : CGImageAlphaInfo.noneSkipLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return }

        // Draw artisanal ShiftKit colors
        context.setFillColor(CGColor(red: 0.85, green: 0.53, blue: 0.41, alpha: hasAlpha ? 0.75 : 1.0))
        context.fill(CGRect(x: 0, y: 0, width: w, height: h))

        context.setFillColor(CGColor(red: 0.27, green: 0.33, blue: 0.26, alpha: 1.0))
        context.fill(CGRect(x: w / 4, y: h / 4, width: w / 2, height: h / 2))

        guard let image = context.makeImage() else { return }

        let uti = url.pathExtension.lowercased() == "png" ? UTType.png.identifier : UTType.jpeg.identifier
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, uti as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
    }
}
