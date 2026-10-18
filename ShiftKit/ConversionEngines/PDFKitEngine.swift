import Foundation
import PDFKit
import AppKit
import CoreGraphics

public final class PDFKitEngine: ConversionEngine {
    public let engineID = "com.shiftkit.engine.pdfkit"
    public let engineName = "PDFKit Native Engine"

    public init() {}

    public func canHandle(action: ConversionAction, fileType: FileType) -> Bool {
        switch fileType {
        case .pdf:
            return true
        case .image:
            // Images can be converted to PDF
            return action.targetFormat == "pdf" || action.id == "img_to_pdf"
        default:
            return false
        }
    }

    public func execute(
        request: ConversionRequest,
        outputURL: URL,
        progressHandler: @Sendable @escaping (Double?, String) -> Void
    ) async throws -> URL {
        let actionID = request.action.id
        let category = request.action.category

        progressHandler(0.05, "Initializing PDF engine...")

        // 1. Image(s) to PDF
        if actionID == "img_to_pdf" || (request.action.targetFormat == "pdf" && request.fileType.isMedia) {
            var imageURLs = [request.sourceURL]
            if let extraPaths = request.options["additionalFiles"]?.split(separator: ",").map(String.init) {
                for path in extraPaths {
                    let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        imageURLs.append(URL(fileURLWithPath: trimmed))
                    }
                }
            }
            return try createPDFFromImages(imageURLs: imageURLs, outputURL: outputURL, progressHandler: progressHandler)
        }

        // Must be a PDF input beyond this point
        guard let document = PDFDocument(url: request.sourceURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to open PDF document at \(request.sourceURL.path).")
        }

        guard document.pageCount > 0 else {
            throw ShiftKitError.conversionFailed(reason: "The PDF document contains no pages.")
        }

        // 2. PDF Merge
        if actionID == "pdf_merge" || category == .merge {
            var inputURLs = [request.sourceURL]
            if let extraPaths = request.options["additionalFiles"]?.split(separator: ",").map(String.init) {
                for path in extraPaths {
                    let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        inputURLs.append(URL(fileURLWithPath: trimmed))
                    }
                }
            }
            return try merge(inputURLs: inputURLs, outputURL: outputURL, progressHandler: progressHandler)
        }

        // 3. PDF Split
        if actionID == "pdf_split" {
            let outputDir = outputURL.deletingPathExtension()
            try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
            let splitFiles = try split(inputURL: request.sourceURL, outputDirectory: outputDir, progressHandler: progressHandler)
            return splitFiles.first ?? outputURL
        }

        // 4. Extract Selected Pages
        if actionID == "pdf_extract_pages" || (category == .extract && request.action.targetFormat == "pdf") {
            let pageRangeStr = request.options["pageRange"] ?? "1"
            let pageIndices = parsePageRange(pageRangeStr, maxCount: document.pageCount)
            guard !pageIndices.isEmpty else {
                throw ShiftKitError.conversionFailed(reason: "No valid pages specified for extraction in '\(pageRangeStr)'.")
            }
            return try extractPages(inputURL: request.sourceURL, pageIndices: pageIndices, outputURL: outputURL, progressHandler: progressHandler)
        }

        // 5. Reorder Pages
        if actionID == "pdf_reorder" {
            let orderStr = request.options["pageOrder"] ?? ""
            let orderIndices = orderStr.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            guard orderIndices.count == document.pageCount else {
                throw ShiftKitError.conversionFailed(reason: "Reorder list count (\(orderIndices.count)) must match document page count (\(document.pageCount)).")
            }
            return try reorderPages(inputURL: request.sourceURL, newOrder: orderIndices, outputURL: outputURL, progressHandler: progressHandler)
        }

        // 6. Rotate Pages
        if actionID.starts(with: "pdf_rotate") {
            let degrees = Int(request.options["degrees"] ?? "90") ?? 90
            var specificIndices: [Int]? = nil
            if let rangeStr = request.options["pageRange"], !rangeStr.isEmpty {
                specificIndices = parsePageRange(rangeStr, maxCount: document.pageCount)
            }
            return try rotatePages(inputURL: request.sourceURL, degrees: degrees, pageIndices: specificIndices, outputURL: outputURL, progressHandler: progressHandler)
        }

        // 7. Crop Pages
        if actionID == "pdf_crop" || (category == .cropOrTrim && request.action.targetFormat == "pdf") {
            let top = Double(request.options["insetTop"] ?? "0") ?? 0
            let left = Double(request.options["insetLeft"] ?? "0") ?? 0
            let bottom = Double(request.options["insetBottom"] ?? "0") ?? 0
            let right = Double(request.options["insetRight"] ?? "0") ?? 0
            let insets = NSEdgeInsets(top: top, left: left, bottom: bottom, right: right)
            return try cropPages(inputURL: request.sourceURL, insets: insets, pageIndices: nil, outputURL: outputURL, progressHandler: progressHandler)
        }

        // 8. Convert PDF Pages to PNG
        if actionID == "pdf_to_images" || actionID == "pdf_to_png" || (category == .convert && request.action.targetFormat == "png") {
            let dpi = Double(request.options["dpi"] ?? "150") ?? 150.0
            let outputDir = outputURL.deletingPathExtension()
            return try renderPagesToImages(
                inputURL: request.sourceURL,
                format: .png,
                dpi: dpi,
                outputDirectory: outputDir,
                outputURL: outputURL,
                progressHandler: progressHandler
            )
        }

        // 9. Convert PDF Pages to JPEG
        if actionID == "pdf_to_jpeg" || (category == .convert && (request.action.targetFormat == "jpeg" || request.action.targetFormat == "jpg")) {
            let dpi = Double(request.options["dpi"] ?? "150") ?? 150.0
            let quality = Double(request.options["quality"] ?? "0.85") ?? 0.85
            let outputDir = outputURL.deletingPathExtension()
            return try renderPagesToImages(
                inputURL: request.sourceURL,
                format: .jpeg,
                dpi: dpi,
                quality: quality,
                outputDirectory: outputDir,
                outputURL: outputURL,
                progressHandler: progressHandler
            )
        }

        // 10. Extract Available Text
        if actionID == "pdf_extract_text" || (category == .extract && request.action.targetFormat == "txt") {
            _ = try extractText(from: request.sourceURL, outputURL: outputURL, progressHandler: progressHandler)
            return outputURL
        }

        // 11. Add Watermark
        if actionID == "pdf_watermark" {
            let text = request.options["watermarkText"] ?? "CONFIDENTIAL"
            let opacity = Double(request.options["opacity"] ?? "0.25") ?? 0.25
            return try addWatermark(
                inputURL: request.sourceURL,
                text: text,
                opacity: opacity,
                outputURL: outputURL,
                progressHandler: progressHandler
            )
        }

        // 12. Add Annotations
        if actionID == "pdf_annotate" {
            let note = request.options["annotationText"] ?? "Reviewed"
            let pageIndex = Int(request.options["pageIndex"] ?? "0") ?? 0
            return try addAnnotation(
                inputURL: request.sourceURL,
                pageIndex: pageIndex,
                bounds: NSRect(x: 50, y: 50, width: 200, height: 40),
                type: .freeText,
                text: note,
                outputURL: outputURL,
                progressHandler: progressHandler
            )
        }

        // 13. PDF Compression & Optimization
        if actionID == "pdf_compress" || category == .compress {
            let targetDPI = Double(request.options["dpi"] ?? "144") ?? 144.0
            let quality = Double(request.options["quality"] ?? "0.70") ?? 0.70
            let stripMetadata = (request.options["stripMetadata"] ?? "true") == "true"
            return try compress(
                inputURL: request.sourceURL,
                outputURL: outputURL,
                targetDPI: targetDPI,
                quality: quality,
                stripMetadata: stripMetadata,
                progressHandler: progressHandler
            )
        }

        // 14. Safe Metadata Clean / Strip
        if actionID == "pdf_strip_metadata" || category == .metadata {
            return try updateMetadata(
                url: request.sourceURL,
                metadata: PDFMetadataInfo(),
                stripRemaining: true,
                outputURL: outputURL,
                progressHandler: progressHandler
            )
        }

        // Default Fallback: Write optimized document
        progressHandler(0.5, "Saving PDF document...")
        guard document.write(to: outputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to write PDF output to \(outputURL.path).")
        }
        progressHandler(1.0, "Completed")
        return outputURL
    }

    // MARK: - Public Core Operations

    /// Merges multiple PDF documents into a single document.
    @discardableResult
    public func merge(
        inputURLs: [URL],
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        progressHandler?(0.1, "Opening documents to merge...")
        let destinationDoc = PDFDocument()

        let totalDocs = inputURLs.count
        guard totalDocs > 0 else {
            throw ShiftKitError.conversionFailed(reason: "No PDF files provided for merge.")
        }

        var totalPagesMerged = 0

        for (docIdx, url) in inputURLs.enumerated() {
            guard let sourceDoc = PDFDocument(url: url) else {
                throw ShiftKitError.conversionFailed(reason: "Could not load PDF document at \(url.lastPathComponent).")
            }

            let pageCount = sourceDoc.pageCount
            for pageIdx in 0..<pageCount {
                if let page = sourceDoc.page(at: pageIdx) {
                    destinationDoc.insert(page, at: destinationDoc.pageCount)
                    totalPagesMerged += 1
                }
            }

            let progressFraction = 0.1 + (Double(docIdx + 1) / Double(totalDocs)) * 0.7
            progressHandler?(progressFraction, "Merged \(url.lastPathComponent) (\(pageCount) pages)...")
        }

        guard totalPagesMerged > 0 else {
            throw ShiftKitError.conversionFailed(reason: "Source documents contain no pages to merge.")
        }

        progressHandler?(0.85, "Writing combined PDF document...")
        guard destinationDoc.write(to: outputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to save merged PDF document.")
        }

        progressHandler?(1.0, "Merged \(totalDocs) PDFs (\(totalPagesMerged) pages).")
        return outputURL
    }

    /// Splits a PDF document into individual single-page documents.
    public func split(
        inputURL: URL,
        outputDirectory: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> [URL] {
        guard let sourceDoc = PDFDocument(url: inputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to open PDF at \(inputURL.path).")
        }

        let pageCount = sourceDoc.pageCount
        guard pageCount > 0 else {
            throw ShiftKitError.conversionFailed(reason: "Document has no pages to split.")
        }

        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let baseName = inputURL.deletingPathExtension().lastPathComponent
        var outputURLs: [URL] = []

        for pageIdx in 0..<pageCount {
            guard let page = sourceDoc.page(at: pageIdx) else { continue }
            let singlePageDoc = PDFDocument()
            singlePageDoc.insert(page, at: 0)

            let pageNumStr = String(format: "%03d", pageIdx + 1)
            let pageURL = outputDirectory.appendingPathComponent("\(baseName)_page_\(pageNumStr).pdf")

            if singlePageDoc.write(to: pageURL) {
                outputURLs.append(pageURL)
            }

            let frac = Double(pageIdx + 1) / Double(pageCount)
            progressHandler?(frac, "Split page \(pageIdx + 1) of \(pageCount)...")
        }

        progressHandler?(1.0, "Split \(outputURLs.count) pages.")
        return outputURLs
    }

    /// Extracts specific page indices (0-based) into a new document.
    @discardableResult
    public func extractPages(
        inputURL: URL,
        pageIndices: [Int],
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        guard let sourceDoc = PDFDocument(url: inputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to open PDF at \(inputURL.path).")
        }

        let newDoc = PDFDocument()
        let validIndices = pageIndices.filter { $0 >= 0 && $0 < sourceDoc.pageCount }

        guard !validIndices.isEmpty else {
            throw ShiftKitError.conversionFailed(reason: "No requested page indices exist in document.")
        }

        for (i, pageIdx) in validIndices.enumerated() {
            if let page = sourceDoc.page(at: pageIdx) {
                newDoc.insert(page, at: newDoc.pageCount)
            }
            let frac = Double(i + 1) / Double(validIndices.count)
            progressHandler?(frac * 0.8, "Extracting page \(pageIdx + 1)...")
        }

        progressHandler?(0.9, "Saving extracted document...")
        guard newDoc.write(to: outputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to write extracted PDF.")
        }

        progressHandler?(1.0, "Extracted \(validIndices.count) pages.")
        return outputURL
    }

    /// Reorders pages according to a list of original 0-based indices.
    @discardableResult
    public func reorderPages(
        inputURL: URL,
        newOrder: [Int],
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        guard let sourceDoc = PDFDocument(url: inputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to open PDF at \(inputURL.path).")
        }

        let newDoc = PDFDocument()
        for (i, pageIdx) in newOrder.enumerated() {
            guard pageIdx >= 0 && pageIdx < sourceDoc.pageCount,
                  let page = sourceDoc.page(at: pageIdx) else {
                throw ShiftKitError.conversionFailed(reason: "Invalid page index \(pageIdx) in reorder list.")
            }
            newDoc.insert(page, at: newDoc.pageCount)
            let frac = Double(i + 1) / Double(newOrder.count)
            progressHandler?(frac * 0.8, "Ordering page \(pageIdx + 1)...")
        }

        progressHandler?(0.9, "Saving reordered PDF...")
        guard newDoc.write(to: outputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to write reordered PDF.")
        }

        progressHandler?(1.0, "Reordered \(newOrder.count) pages.")
        return outputURL
    }

    /// Rotates pages clockwise by a multiple of 90 degrees (e.g. 90, 180, 270).
    @discardableResult
    public func rotatePages(
        inputURL: URL,
        degrees: Int,
        pageIndices: [Int]? = nil,
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        guard let document = PDFDocument(url: inputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to open PDF at \(inputURL.path).")
        }

        let total = document.pageCount
        let targets = Set(pageIndices ?? Array(0..<total))

        for idx in 0..<total {
            if targets.contains(idx), let page = document.page(at: idx) {
                let current = page.rotation
                let updated = (current + degrees) % 360
                page.rotation = updated >= 0 ? updated : updated + 360
            }
            let frac = Double(idx + 1) / Double(total)
            progressHandler?(frac * 0.8, "Rotating page \(idx + 1)...")
        }

        progressHandler?(0.9, "Saving rotated PDF...")
        guard document.write(to: outputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to write rotated PDF.")
        }

        progressHandler?(1.0, "Rotated \(targets.count) pages by \(degrees)°.")
        return outputURL
    }

    /// Crops pages according to edge insets.
    @discardableResult
    public func cropPages(
        inputURL: URL,
        insets: NSEdgeInsets,
        pageIndices: [Int]? = nil,
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        guard let document = PDFDocument(url: inputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to open PDF at \(inputURL.path).")
        }

        let total = document.pageCount
        let targets = Set(pageIndices ?? Array(0..<total))

        for idx in 0..<total {
            if targets.contains(idx), let page = document.page(at: idx) {
                let currentBox = page.bounds(for: .cropBox)
                let newX = currentBox.origin.x + insets.left
                let newY = currentBox.origin.y + insets.bottom
                let newW = max(10, currentBox.size.width - insets.left - insets.right)
                let newH = max(10, currentBox.size.height - insets.top - insets.bottom)

                page.setBounds(NSRect(x: newX, y: newY, width: newW, height: newH), for: .cropBox)
            }
            let frac = Double(idx + 1) / Double(total)
            progressHandler?(frac * 0.8, "Cropping page \(idx + 1)...")
        }

        progressHandler?(0.9, "Saving cropped PDF...")
        guard document.write(to: outputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to write cropped PDF.")
        }

        progressHandler?(1.0, "Cropped \(targets.count) pages.")
        return outputURL
    }

    /// Creates a PDF from one or more images.
    @discardableResult
    public func createPDFFromImages(
        imageURLs: [URL],
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        progressHandler?(0.1, "Preparing images for PDF...")
        let doc = PDFDocument()

        guard !imageURLs.isEmpty else {
            throw ShiftKitError.conversionFailed(reason: "No images supplied to generate PDF.")
        }

        for (idx, imgURL) in imageURLs.enumerated() {
            guard let image = NSImage(contentsOf: imgURL) else {
                throw ShiftKitError.conversionFailed(reason: "Could not load image at \(imgURL.lastPathComponent).")
            }

            guard let page = PDFPage(image: image) else {
                throw ShiftKitError.conversionFailed(reason: "Could not create PDF page for \(imgURL.lastPathComponent).")
            }

            doc.insert(page, at: doc.pageCount)
            let frac = 0.1 + (Double(idx + 1) / Double(imageURLs.count)) * 0.7
            progressHandler?(frac, "Added \(imgURL.lastPathComponent)...")
        }

        progressHandler?(0.85, "Writing PDF document...")
        guard doc.write(to: outputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to save created PDF document.")
        }

        progressHandler?(1.0, "Created PDF from \(imageURLs.count) images.")
        return outputURL
    }

    public enum ImageExportFormat {
        case png
        case jpeg
    }

    /// Renders PDF pages to image files (PNG or JPEG).
    @discardableResult
    public func renderPagesToImages(
        inputURL: URL,
        format: ImageExportFormat,
        dpi: Double = 150.0,
        quality: Double = 0.85,
        outputDirectory: URL,
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        guard let document = PDFDocument(url: inputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to open PDF at \(inputURL.path).")
        }

        let pageCount = document.pageCount
        guard pageCount > 0 else {
            throw ShiftKitError.conversionFailed(reason: "Document has no pages to render.")
        }

        let scale = CGFloat(max(0.5, dpi / 72.0))
        let ext = format == .png ? "png" : "jpeg"
        let bitmapType: NSBitmapImageRep.FileType = format == .png ? .png : .jpeg

        // If single page and outputURL is specifically a file URL with matching extension:
        if pageCount == 1 || outputURL.pathExtension.lowercased() == ext {
            if let page = document.page(at: 0),
               let data = renderPageData(page: page, scale: scale, format: bitmapType, quality: quality) {
                try data.write(to: outputURL)
                progressHandler?(1.0, "Rendered page to \(ext.uppercased()).")
                return outputURL
            }
        }

        // Multi-page export into directory
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let baseName = inputURL.deletingPathExtension().lastPathComponent
        var firstPageURL: URL? = nil

        for idx in 0..<pageCount {
            guard let page = document.page(at: idx),
                  let data = renderPageData(page: page, scale: scale, format: bitmapType, quality: quality) else {
                continue
            }

            let numStr = String(format: "%03d", idx + 1)
            let pageFileURL = outputDirectory.appendingPathComponent("\(baseName)_page_\(numStr).\(ext)")
            try data.write(to: pageFileURL)

            if firstPageURL == nil {
                firstPageURL = pageFileURL
            }

            let frac = Double(idx + 1) / Double(pageCount)
            progressHandler?(frac, "Rendered page \(idx + 1) of \(pageCount)...")
        }

        progressHandler?(1.0, "Exported \(pageCount) pages as \(ext.uppercased()).")
        return firstPageURL ?? outputURL
    }

    /// Extracts available text stream from all pages of a PDF document.
    public func extractText(
        from inputURL: URL,
        outputURL: URL? = nil,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> String {
        guard let document = PDFDocument(url: inputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to open PDF at \(inputURL.path).")
        }

        let count = document.pageCount
        var fullText = ""

        for idx in 0..<count {
            let pageStr = document.page(at: idx)?.string ?? ""
            fullText += "--- Page \(idx + 1) ---\n" + pageStr + "\n\n"

            let frac = Double(idx + 1) / Double(count)
            progressHandler?(frac * 0.85, "Extracted text from page \(idx + 1)...")
        }

        if let dest = outputURL {
            try fullText.write(to: dest, atomically: true, encoding: .utf8)
        }

        progressHandler?(1.0, "Extracted text from \(count) pages.")
        return fullText
    }

    /// Adds a diagonal text watermark across every page of the document.
    @discardableResult
    public func addWatermark(
        inputURL: URL,
        text: String,
        color: NSColor = .gray,
        angle: CGFloat = 45.0,
        opacity: CGFloat = 0.25,
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        guard let sourceDoc = PDFDocument(url: inputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to open PDF at \(inputURL.path).")
        }

        let count = sourceDoc.pageCount
        guard count > 0 else {
            throw ShiftKitError.conversionFailed(reason: "No pages to watermark.")
        }

        // Create PDF graphics context to burn watermark directly into the output stream
        guard let consumer = CGDataConsumer(url: outputURL as CFURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to create PDF writer.")
        }

        var mediaBox = sourceDoc.page(at: 0)?.bounds(for: .mediaBox) ?? CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to initialize PDF context.")
        }

        for idx in 0..<count {
            guard let page = sourceDoc.page(at: idx) else { continue }
            var pageRect = page.bounds(for: .mediaBox)

            context.beginPage(mediaBox: &pageRect)

            // Draw original page
            NSGraphicsContext.saveGraphicsState()
            let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.current = nsContext
            page.draw(with: .mediaBox, to: context)

            // Draw Watermark
            context.saveGState()
            context.setAlpha(opacity)

            let font = NSFont.boldSystemFont(ofSize: min(pageRect.width, pageRect.height) * 0.12)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color
            ]

            let attrString = NSAttributedString(string: text, attributes: attributes)
            let textSize = attrString.size()

            // Translate to center and rotate
            context.translateBy(x: pageRect.midX, y: pageRect.midY)
            context.rotate(by: angle * .pi / 180.0)

            let textRect = NSRect(
                x: -textSize.width / 2.0,
                y: -textSize.height / 2.0,
                width: textSize.width,
                height: textSize.height
            )
            attrString.draw(in: textRect)

            context.restoreGState()
            NSGraphicsContext.restoreGraphicsState()

            context.endPage()

            let frac = Double(idx + 1) / Double(count)
            progressHandler?(frac * 0.9, "Watermarked page \(idx + 1)...")
        }

        context.closePDF()
        progressHandler?(1.0, "Watermarked \(count) pages.")
        return outputURL
    }

    /// Adds a supported annotation (e.g. FreeText, Highlight, Note) to a specific page.
    @discardableResult
    public func addAnnotation(
        inputURL: URL,
        pageIndex: Int,
        bounds: NSRect,
        type: PDFAnnotationSubtype,
        text: String,
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        guard let document = PDFDocument(url: inputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to open PDF at \(inputURL.path).")
        }

        guard pageIndex >= 0 && pageIndex < document.pageCount,
              let page = document.page(at: pageIndex) else {
            throw ShiftKitError.conversionFailed(reason: "Invalid page index \(pageIndex) for annotation.")
        }

        let annotation = PDFAnnotation(bounds: bounds, forType: type, withProperties: nil)
        annotation.contents = text
        annotation.color = NSColor(red: 0.85, green: 0.53, blue: 0.41, alpha: 0.8) // ShiftKit Terracotta tone

        page.addAnnotation(annotation)

        progressHandler?(0.8, "Writing annotated document...")
        guard document.write(to: outputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to write annotated PDF.")
        }

        progressHandler?(1.0, "Added annotation to page \(pageIndex + 1).")
        return outputURL
    }

    /// Inspects PDF metadata.
    public func inspectMetadata(url: URL) throws -> PDFMetadataInfo {
        guard let document = PDFDocument(url: url) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to open PDF at \(url.path).")
        }

        let attr = document.documentAttributes ?? [:]
        let title = attr[PDFDocumentAttribute.titleAttribute] as? String
        let author = attr[PDFDocumentAttribute.authorAttribute] as? String
        let subject = attr[PDFDocumentAttribute.subjectAttribute] as? String
        let creator = attr[PDFDocumentAttribute.creatorAttribute] as? String
        let producer = attr[PDFDocumentAttribute.producerAttribute] as? String
        let creationDate = attr[PDFDocumentAttribute.creationDateAttribute] as? Date
        let modDate = attr[PDFDocumentAttribute.modificationDateAttribute] as? Date

        var keywordsList: [String] = []
        if let kw = attr[PDFDocumentAttribute.keywordsAttribute] as? [String] {
            keywordsList = kw
        } else if let kwStr = attr[PDFDocumentAttribute.keywordsAttribute] as? String {
            keywordsList = kwStr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }

        var pageSizeDesc = ""
        if let first = document.page(at: 0) {
            let box = first.bounds(for: .mediaBox)
            pageSizeDesc = "\(Int(box.width)) × \(Int(box.height)) pt"
            if abs(box.width - 612) < 2 && abs(box.height - 792) < 2 {
                pageSizeDesc = "US Letter (\(pageSizeDesc))"
            } else if abs(box.width - 595) < 2 && abs(box.height - 842) < 2 {
                pageSizeDesc = "A4 (\(pageSizeDesc))"
            }
        }

        var hasText = false
        for i in 0..<min(3, document.pageCount) {
            if let str = document.page(at: i)?.string, !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                hasText = true
                break
            }
        }

        return PDFMetadataInfo(
            title: title,
            author: author,
            subject: subject,
            keywords: keywordsList,
            creator: creator,
            producer: producer,
            creationDate: creationDate,
            modificationDate: modDate,
            pageCount: document.pageCount,
            majorVersion: document.majorVersion,
            minorVersion: document.minorVersion,
            isEncrypted: document.isEncrypted,
            isLocked: document.isLocked,
            allowsPrinting: document.allowsPrinting,
            allowsCopying: document.allowsCopying,
            pageSizeSummary: pageSizeDesc,
            hasText: hasText
        )
    }

    /// Updates or strips metadata from a PDF.
    @discardableResult
    public func updateMetadata(
        url: URL,
        metadata: PDFMetadataInfo,
        stripRemaining: Bool = false,
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        guard let document = PDFDocument(url: url) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to open PDF at \(url.path).")
        }

        progressHandler?(0.2, "Updating PDF metadata...")

        var newAttr: [AnyHashable: Any] = stripRemaining ? [:] : (document.documentAttributes ?? [:])

        if stripRemaining {
            newAttr.removeAll()
        }

        if let title = metadata.title {
            newAttr[PDFDocumentAttribute.titleAttribute] = title
        }
        if let author = metadata.author {
            newAttr[PDFDocumentAttribute.authorAttribute] = author
        }
        if let subject = metadata.subject {
            newAttr[PDFDocumentAttribute.subjectAttribute] = subject
        }
        if !metadata.keywords.isEmpty {
            newAttr[PDFDocumentAttribute.keywordsAttribute] = metadata.keywords
        }
        if let creator = metadata.creator {
            newAttr[PDFDocumentAttribute.creatorAttribute] = creator
        }
        newAttr[PDFDocumentAttribute.modificationDateAttribute] = Date()

        document.documentAttributes = newAttr

        progressHandler?(0.8, "Writing updated PDF...")
        guard document.write(to: outputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to write metadata-updated PDF.")
        }

        progressHandler?(1.0, "Updated metadata successfully.")
        return outputURL
    }

    /// Compresses a PDF via raster downsampling, JPEG recompression, and stream optimization.
    @discardableResult
    public func compress(
        inputURL: URL,
        outputURL: URL,
        targetDPI: Double = 144.0,
        quality: Double = 0.70,
        stripMetadata: Bool = true,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        guard let document = PDFDocument(url: inputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to open PDF at \(inputURL.path).")
        }

        let count = document.pageCount
        guard count > 0 else {
            throw ShiftKitError.conversionFailed(reason: "PDF document has no pages.")
        }

        progressHandler?(0.1, "Optimizing PDF pages (target \(Int(targetDPI)) DPI)...")

        let optimizedDoc = PDFDocument()
        let scale = CGFloat(max(0.5, targetDPI / 72.0))

        for idx in 0..<count {
            guard let page = document.page(at: idx),
                  let jpegData = renderPageData(page: page, scale: scale, format: .jpeg, quality: quality),
                  let recompressedImage = NSImage(data: jpegData),
                  let optimizedPage = PDFPage(image: recompressedImage) else {
                // If rendering fails, keep original page
                if let fallback = document.page(at: idx) {
                    optimizedDoc.insert(fallback, at: optimizedDoc.pageCount)
                }
                continue
            }

            // Restore original rotation and crop bounds if needed
            optimizedPage.rotation = page.rotation
            optimizedDoc.insert(optimizedPage, at: optimizedDoc.pageCount)

            let frac = 0.1 + (Double(idx + 1) / Double(count)) * 0.75
            progressHandler?(frac, "Optimized page \(idx + 1) of \(count)...")
        }

        if stripMetadata {
            optimizedDoc.documentAttributes = [
                PDFDocumentAttribute.producerAttribute: "ShiftKit Local Engine",
                PDFDocumentAttribute.modificationDateAttribute: Date()
            ]
        }

        progressHandler?(0.9, "Saving optimized PDF...")
        guard optimizedDoc.write(to: outputURL) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to write compressed PDF.")
        }

        // Validate resulting file size
        let originalSize = (try? FileManager.default.attributesOfItem(atPath: inputURL.path)[.size] as? Int64) ?? 0
        let newSize = (try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int64) ?? 0

        // If compression resulted in larger file (e.g. pure vector text blown up into bitmap), write native optimized version
        if originalSize > 0 && newSize > originalSize {
            progressHandler?(0.95, "Bitmap recompression was larger than original vector stream. Preserving native vector PDF...")
            guard document.write(to: outputURL) else {
                throw ShiftKitError.conversionFailed(reason: "Failed to save fallback PDF.")
            }
        }

        progressHandler?(1.0, "Completed PDF optimization.")
        return outputURL
    }

    /// Generates a thumbnail for a given page.
    public func generateThumbnail(
        for url: URL,
        pageIndex: Int = 0,
        targetSize: CGSize = CGSize(width: 160, height: 220)
    ) throws -> NSImage {
        guard let doc = PDFDocument(url: url),
              pageIndex >= 0 && pageIndex < doc.pageCount,
              let page = doc.page(at: pageIndex) else {
            throw ShiftKitError.conversionFailed(reason: "Could not load thumbnail for page \(pageIndex).")
        }
        return page.thumbnail(of: targetSize, for: .mediaBox)
    }

    // MARK: - Private Helper Methods

    private func renderPageData(
        page: PDFPage,
        scale: CGFloat,
        format: NSBitmapImageRep.FileType,
        quality: Double = 0.85
    ) -> Data? {
        let pageRect = page.bounds(for: .mediaBox)
        let targetWidth = max(1, Int(pageRect.width * scale))
        let targetHeight = max(1, Int(pageRect.height * scale))

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: targetWidth,
            pixelsHigh: targetHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = context

        // Draw solid white background
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight).fill()

        if let cg = context?.cgContext {
            cg.saveGState()
            cg.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: cg)
            cg.restoreGState()
        }

        NSGraphicsContext.restoreGraphicsState()

        let properties: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: quality
        ]
        return rep.representation(using: format, properties: properties)
    }

    private func parsePageRange(_ rangeStr: String, maxCount: Int) -> [Int] {
        var result = Set<Int>()
        let tokens = rangeStr.split(separator: ",")

        for token in tokens {
            let trimmed = token.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("-") {
                let parts = trimmed.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count == 2, let start = Int(parts[0]), let end = Int(parts[1]) {
                    let rangeStart = max(1, min(start, end))
                    let rangeEnd = min(maxCount, max(start, end))
                    if rangeStart <= rangeEnd {
                        for p in rangeStart...rangeEnd {
                            result.insert(p - 1) // 0-based
                        }
                    }
                }
            } else if let single = Int(trimmed) {
                if single >= 1 && single <= maxCount {
                    result.insert(single - 1) // 0-based
                }
            }
        }

        return result.sorted()
    }
}
