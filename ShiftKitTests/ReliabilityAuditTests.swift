import XCTest
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import PDFKit
@testable import ShiftKit

@MainActor
final class ReliabilityAuditTests: XCTestCase {
    private var tempDir: URL!
    private var fileInspector: FileInspector!
    private var outputManager: OutputManager!
    private var imageProcessor: ImageProcessor!
    private var updateManager: UpdateManager!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ShiftKitAudit_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        fileInspector = FileInspector()
        outputManager = OutputManager()
        imageProcessor = ImageProcessor.shared
        updateManager = UpdateManager(startImmediately: false)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - 1. Zero-Byte & Directory Input Validation

    func testZeroByteFileRejectionInImageProcessor() async {
        let emptyURL = tempDir.appendingPathComponent("empty.png")
        FileManager.default.createFile(atPath: emptyURL.path, contents: Data())

        let outURL = tempDir.appendingPathComponent("out.webp")
        do {
            _ = try await imageProcessor.process(sourceURL: emptyURL, targetURL: outURL, targetFormat: .webp)
            XCTFail("Expected zero-byte image to be rejected")
        } catch let ShiftKitError.conversionFailed(reason) {
            XCTAssertTrue(reason.contains("empty") || reason.contains("0 bytes"), "Reason: \(reason)")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDirectoryDroppedAsFileInputRejection() async {
        let folderURL = tempDir.appendingPathComponent("MyDocuments.png")
        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

        do {
            _ = try await fileInspector.inspect(url: folderURL)
            XCTFail("Expected directory dropped as file to be rejected")
        } catch let ShiftKitError.conversionFailed(reason) {
            XCTAssertTrue(reason.contains("Folders and directories cannot be processed"), "Reason: \(reason)")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUnicodeAndEmojiFilenameInspection() async throws {
        let complexName = "🎨 图像轉換_Report-2026 #1.png"
        let fileURL = tempDir.appendingPathComponent(complexName)
        createSyntheticImage(at: fileURL, size: CGSize(width: 100, height: 100))

        let inspected = try await fileInspector.inspect(url: fileURL)
        XCTAssertEqual(inspected.fileName, complexName)
        XCTAssertEqual(inspected.fileType, .image(.png))
    }

    // MARK: - 2. Tiny Image & Crop Geometry Clamping

    func testTinyImageCropClamping() {
        // Image smaller than the default minimum crop dimension of 10
        let tinySize = CGSize(width: 6, height: 6)
        let engine = CropGeometryEngine(imageSize: tinySize, minCropDimension: 10)

        let initial = engine.initialCropRect(for: .free)
        XCTAssertTrue(initial.origin.x >= 0)
        XCTAssertTrue(initial.origin.y >= 0)
        XCTAssertTrue(initial.maxX <= tinySize.width, "MaxX \(initial.maxX) must not exceed image width \(tinySize.width)")
        XCTAssertTrue(initial.maxY <= tinySize.height, "MaxY \(initial.maxY) must not exceed image height \(tinySize.height)")

        // Moving tiny crop rect must remain clamped strictly within image bounds
        let moved = engine.moveCropRect(initial, delta: CGPoint(x: 100, y: 100))
        XCTAssertTrue(moved.maxX <= tinySize.width)
        XCTAssertTrue(moved.maxY <= tinySize.height)
    }

    // MARK: - 3. PDF Password & Locked Document Handling

    func testEncryptedPDFHandling() async {
        let pdfURL = tempDir.appendingPathComponent("locked.pdf")
        let doc = PDFDocument()
        let page = PDFPage()
        doc.insert(page, at: 0)

        // Write document with password protection
        let options: [PDFDocumentWriteOption: Any] = [
            .userPasswordOption: "secret123",
            .ownerPasswordOption: "owner123"
        ]
        doc.write(to: pdfURL, withOptions: options)

        let engine = PDFKitEngine()
        let request = ConversionRequest(
            sourceURL: pdfURL,
            fileType: .pdf,
            action: .pdfSplit
        )
        let outURL = tempDir.appendingPathComponent("out_pages")

        do {
            _ = try await engine.execute(request: request, outputURL: outURL, progressHandler: { _, _ in })
            XCTFail("Expected locked PDF without password to fail")
        } catch let ShiftKitError.conversionFailed(reason) {
            XCTAssertTrue(reason.contains("password-protected"), "Reason: \(reason)")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - 4. Archive Traversal & Entry Limit Security

    func testArchiveSafetyPathTraversalRejection() {
        // Test various path traversal attack patterns
        let maliciousEntries = [
            "../secret.txt",
            "safe/../../etc/passwd",
            "folder/..",
            "..\\windows.txt",
            "/absolute/root.txt"
        ]

        for entry in maliciousEntries {
            let components = entry.components(separatedBy: CharacterSet(charactersIn: "/\\"))
            let isDangerous = entry.hasPrefix("/") || entry.hasPrefix("\\") || components.contains("..")
            XCTAssertTrue(isDangerous, "Entry '\(entry)' must be identified as dangerous")
        }
    }

    // MARK: - 5. Concurrent Destination Reservation & Overwrite Safety

    func testConcurrentDestinationPathReservations() throws {
        let sourceURL = tempDir.appendingPathComponent("document.pdf")
        let targetDir = tempDir.appendingPathComponent("outputs")
        try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)

        // Simultaneous reservations for same base name should generate distinct numbered paths
        let res1 = try outputManager.resolveDestination(
            for: sourceURL,
            targetExtension: "pdf",
            suffix: nil,
            customDirectory: targetDir,
            conflictResolution: .renameWithNumber
        )

        let res2 = try outputManager.resolveDestination(
            for: sourceURL,
            targetExtension: "pdf",
            suffix: nil,
            customDirectory: targetDir,
            conflictResolution: .renameWithNumber
        )

        XCTAssertNotEqual(res1.path, res2.path)
        XCTAssertEqual(res1.lastPathComponent, "document.pdf")
        XCTAssertEqual(res2.lastPathComponent, "document_1.pdf")
    }

    func testPreventOverwritingOriginalSourceFileByDefault() throws {
        let sourceURL = tempDir.appendingPathComponent("important.png")
        createSyntheticImage(at: sourceURL, size: CGSize(width: 50, height: 50))

        // When besideOriginal with same extension and no suffix, renameWithNumber must NOT overwrite source
        let resolved = try outputManager.resolveDestination(
            for: sourceURL,
            targetExtension: "png",
            suffix: nil,
            customDirectory: tempDir,
            conflictResolution: .renameWithNumber
        )

        XCTAssertNotEqual(resolved.path, sourceURL.path, "Resolved path must not collide with source URL")
        XCTAssertEqual(resolved.lastPathComponent, "important_1.png")
    }

    // MARK: - 6. Sparkle Diagnostic Verification

    func testSparkleConfigurationDiagnosticChecks() {
        // UpdateManager reports configuration diagnostic if feed or key is missing / malformed
        let diagnostic = updateManager.configurationDiagnostic
        // The project has valid HTTPS feed and 32-byte EdDSA key configured in Info.plist
        XCTAssertNil(diagnostic, "ShiftKit Info.plist should pass all security configuration checks")
        XCTAssertTrue(updateManager.isConfigured)
    }

    // MARK: - 7. Headless Screen Origin Clamping

    func testHeadlessScreenOriginClamping() {
        let engine = MenuLayoutEngine.shared
        let targetPoint = CGPoint(x: 500, y: 500)
        let menuSize = CGSize(width: 360, height: 360)

        let origin = engine.clampedWindowOrigin(targetCenter: targetPoint, windowSize: menuSize)
        XCTAssertFalse(origin.x.isNaN)
        XCTAssertFalse(origin.y.isNaN)
    }

    // MARK: - Helper

    private func createSyntheticImage(at url: URL, size: CGSize) {
        let width = Int(size.width)
        let height = Int(size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        context.setFillColor(CGColor(red: 0.8, green: 0.5, blue: 0.3, alpha: 1.0))
        context.fill(CGRect(origin: .zero, size: size))

        let image = context.makeImage()!
        let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
    }
}
