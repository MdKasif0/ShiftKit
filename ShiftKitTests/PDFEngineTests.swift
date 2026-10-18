import XCTest
import PDFKit
import AppKit
@testable import ShiftKit

final class PDFEngineTests: XCTestCase {
    var engine: PDFKitEngine!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        engine = PDFKitEngine()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("PDFTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    private func createSampleImage(label: String) -> URL {
        let size = NSSize(width: 150, height: 150)
        let img = NSImage(size: size)
        img.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        (label as NSString).draw(at: NSPoint(x: 20, y: 60), withAttributes: [.font: NSFont.systemFont(ofSize: 18)])
        img.unlockFocus()

        let url = tempDirectory.appendingPathComponent("\(label).png")
        if let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: url)
        }
        return url
    }

    private func createSamplePDF(pageCount: Int, prefix: String = "Page") -> URL {
        let doc = PDFDocument()
        for i in 0..<pageCount {
            let imgURL = createSampleImage(label: "\(prefix) \(i + 1)")
            if let img = NSImage(contentsOf: imgURL), let page = PDFPage(image: img) {
                doc.insert(page, at: doc.pageCount)
            }
        }
        let url = tempDirectory.appendingPathComponent("\(prefix)_doc.pdf")
        doc.write(to: url)
        return url
    }

    func testCreatePDFFromImages() throws {
        let img1 = createSampleImage(label: "Image1")
        let img2 = createSampleImage(label: "Image2")
        let img3 = createSampleImage(label: "Image3")

        let outURL = tempDirectory.appendingPathComponent("images_to_pdf.pdf")
        let result = try engine.createPDFFromImages(imageURLs: [img1, img2, img3], outputURL: outURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
        guard let doc = PDFDocument(url: result) else {
            XCTFail("Output document could not be opened as PDF")
            return
        }
        XCTAssertEqual(doc.pageCount, 3)
    }

    func testPDFMerge() throws {
        let pdf1 = createSamplePDF(pageCount: 2, prefix: "DocA")
        let pdf2 = createSamplePDF(pageCount: 3, prefix: "DocB")

        let mergedURL = tempDirectory.appendingPathComponent("merged.pdf")
        let result = try engine.merge(inputURLs: [pdf1, pdf2], outputURL: mergedURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
        guard let doc = PDFDocument(url: result) else {
            XCTFail("Merged PDF could not be opened")
            return
        }
        XCTAssertEqual(doc.pageCount, 5)
    }

    func testPDFSplit() throws {
        let sourcePDF = createSamplePDF(pageCount: 3, prefix: "SplitSource")
        let splitDir = tempDirectory.appendingPathComponent("split_pages")

        let splitFiles = try engine.split(inputURL: sourcePDF, outputDirectory: splitDir)

        XCTAssertEqual(splitFiles.count, 3)
        for pageURL in splitFiles {
            XCTAssertTrue(FileManager.default.fileExists(atPath: pageURL.path))
            guard let pageDoc = PDFDocument(url: pageURL) else {
                XCTFail("Split page could not be opened")
                continue
            }
            XCTAssertEqual(pageDoc.pageCount, 1)
        }
    }

    func testPDFExtractSelectedPages() throws {
        let sourcePDF = createSamplePDF(pageCount: 5, prefix: "ExtractDoc")
        let extractedURL = tempDirectory.appendingPathComponent("extracted.pdf")

        // Extract pages 0, 2, 4 (pages 1, 3, 5)
        let result = try engine.extractPages(inputURL: sourcePDF, pageIndices: [0, 2, 4], outputURL: extractedURL)

        guard let doc = PDFDocument(url: result) else {
            XCTFail("Extracted PDF could not be opened")
            return
        }
        XCTAssertEqual(doc.pageCount, 3)
    }

    func testPDFReorderPages() throws {
        let sourcePDF = createSamplePDF(pageCount: 3, prefix: "ReorderDoc")
        let reorderedURL = tempDirectory.appendingPathComponent("reordered.pdf")

        let result = try engine.reorderPages(inputURL: sourcePDF, newOrder: [2, 0, 1], outputURL: reorderedURL)

        guard let doc = PDFDocument(url: result) else {
            XCTFail("Reordered PDF could not be opened")
            return
        }
        XCTAssertEqual(doc.pageCount, 3)
    }

    func testPDFRotatePages() throws {
        let sourcePDF = createSamplePDF(pageCount: 2, prefix: "RotateDoc")
        let rotatedURL = tempDirectory.appendingPathComponent("rotated.pdf")

        let result = try engine.rotatePages(inputURL: sourcePDF, degrees: 90, pageIndices: nil, outputURL: rotatedURL)

        guard let doc = PDFDocument(url: result), let page0 = doc.page(at: 0) else {
            XCTFail("Rotated PDF could not be opened")
            return
        }
        XCTAssertEqual(page0.rotation, 90)
    }

    func testPDFCropPages() throws {
        let sourcePDF = createSamplePDF(pageCount: 1, prefix: "CropDoc")
        let croppedURL = tempDirectory.appendingPathComponent("cropped.pdf")

        let insets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let result = try engine.cropPages(inputURL: sourcePDF, insets: insets, outputURL: croppedURL)

        guard let doc = PDFDocument(url: result), let page = doc.page(at: 0) else {
            XCTFail("Cropped PDF could not be opened")
            return
        }
        let cropBox = page.bounds(for: .cropBox)
        XCTAssertTrue(cropBox.width > 0 && cropBox.height > 0)
    }

    func testPDFPagesToPNGAndJPEG() throws {
        let sourcePDF = createSamplePDF(pageCount: 2, prefix: "RenderDoc")

        // Render to PNG
        let pngOut = tempDirectory.appendingPathComponent("page_out.png")
        let pngResult = try engine.renderPagesToImages(
            inputURL: sourcePDF,
            format: .png,
            dpi: 144.0,
            outputDirectory: tempDirectory.appendingPathComponent("png_pages"),
            outputURL: pngOut
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: pngResult.path))

        // Render to JPEG
        let jpegOut = tempDirectory.appendingPathComponent("page_out.jpeg")
        let jpegResult = try engine.renderPagesToImages(
            inputURL: sourcePDF,
            format: .jpeg,
            dpi: 144.0,
            quality: 0.8,
            outputDirectory: tempDirectory.appendingPathComponent("jpeg_pages"),
            outputURL: jpegOut
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: jpegResult.path))
    }

    func testPDFWatermarkAndAnnotation() throws {
        let sourcePDF = createSamplePDF(pageCount: 2, prefix: "WatermarkDoc")
        let watermarkedURL = tempDirectory.appendingPathComponent("watermarked.pdf")

        let result = try engine.addWatermark(
            inputURL: sourcePDF,
            text: "CONFIDENTIAL",
            opacity: 0.3,
            outputURL: watermarkedURL
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
        guard let doc = PDFDocument(url: result) else {
            XCTFail("Watermarked PDF could not be opened")
            return
        }
        XCTAssertEqual(doc.pageCount, 2)

        // Annotate page 0
        let annotatedURL = tempDirectory.appendingPathComponent("annotated.pdf")
        let annotResult = try engine.addAnnotation(
            inputURL: watermarkedURL,
            pageIndex: 0,
            bounds: NSRect(x: 20, y: 20, width: 100, height: 30),
            type: .freeText,
            text: "Approved by ShiftKit",
            outputURL: annotatedURL
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: annotResult.path))
    }

    func testPDFMetadataInspectionAndModification() throws {
        let sourcePDF = createSamplePDF(pageCount: 2, prefix: "MetaDoc")
        let updatedURL = tempDirectory.appendingPathComponent("meta_updated.pdf")

        let newMetadata = PDFMetadataInfo(
            title: "ShiftKit Whitepaper",
            author: "Antigravity Team",
            subject: "Local File Processing",
            keywords: ["macos", "utility", "local"]
        )

        let result = try engine.updateMetadata(
            url: sourcePDF,
            metadata: newMetadata,
            stripRemaining: false,
            outputURL: updatedURL
        )

        let inspected = try engine.inspectMetadata(url: result)
        XCTAssertEqual(inspected.title, "ShiftKit Whitepaper")
        XCTAssertEqual(inspected.author, "Antigravity Team")
        XCTAssertEqual(inspected.pageCount, 2)
    }

    func testPDFCompression() throws {
        let sourcePDF = createSamplePDF(pageCount: 2, prefix: "CompressDoc")
        let compressedURL = tempDirectory.appendingPathComponent("compressed.pdf")

        let result = try engine.compress(
            inputURL: sourcePDF,
            outputURL: compressedURL,
            targetDPI: 72.0,
            quality: 0.5,
            stripMetadata: true
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
        guard let doc = PDFDocument(url: result) else {
            XCTFail("Compressed PDF could not be loaded")
            return
        }
        XCTAssertEqual(doc.pageCount, 2)
    }

    func testMalformedPDFHandling() {
        let corruptURL = tempDirectory.appendingPathComponent("corrupt.pdf")
        try? "Not a real PDF header".write(to: corruptURL, atomically: true, encoding: .utf8)

        XCTAssertThrowsError(try engine.inspectMetadata(url: corruptURL))
        XCTAssertThrowsError(try engine.extractPages(inputURL: corruptURL, pageIndices: [0], outputURL: tempDirectory.appendingPathComponent("fail.pdf")))
    }
}
