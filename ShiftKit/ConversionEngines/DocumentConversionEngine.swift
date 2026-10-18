import Foundation
import AppKit
import CoreText
import PDFKit

public final class DocumentConversionEngine: ConversionEngine {
    public let engineID = "com.shiftkit.engine.document"
    public let engineName = "Universal Document Engine"

    public init() {}

    public static var libreOfficePath: String? {
        let candidates = [
            "/Applications/LibreOffice.app/Contents/MacOS/soffice",
            "/opt/homebrew/bin/soffice",
            "/usr/local/bin/soffice"
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }

    public static var pandocPath: String? {
        let candidates = [
            "/opt/homebrew/bin/pandoc",
            "/usr/local/bin/pandoc",
            "/usr/bin/pandoc"
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }

    public static var isLibreOfficeAvailable: Bool {
        return libreOfficePath != nil
    }

    public static var isPandocAvailable: Bool {
        return pandocPath != nil
    }

    public func canHandle(action: ConversionAction, fileType: FileType) -> Bool {
        switch fileType {
        case .document, .archive:
            return true
        default:
            let devActionIDs = [
                "zip_create", "zip_extract", "hash_sha256", "base64_encode",
                "base64_decode", "json_format", "json_to_yaml", "yaml_to_json"
            ]
            return devActionIDs.contains(action.id) || action.targetFormat == "zip"
        }
    }

    public func execute(
        request: ConversionRequest,
        outputURL: URL,
        progressHandler: @Sendable @escaping (Double?, String) -> Void
    ) async throws -> URL {
        let srcExt = request.sourceURL.pathExtension.lowercased()
        let targetExt = (request.action.targetFormat ?? outputURL.pathExtension).lowercased()

        guard outputURL.standardizedFileURL.path != request.sourceURL.standardizedFileURL.path else {
            throw ShiftKitError.conversionFailed(reason: "Output destination cannot overwrite original source file.")
        }

        progressHandler(0.05, "Analyzing document format (\(srcExt.uppercased()) to \(targetExt.uppercased()))...")

        // 0. Developer Utilities & Archive Operations
        if request.action.id == "zip_create" || (targetExt == "zip" && request.action.category == .compress) {
            progressHandler(0.3, "Creating safe ZIP archive...")
            _ = try DeveloperUtilities.createZip(sourceURL: request.sourceURL, destinationZipURL: outputURL)
            progressHandler(1.0, "Created ZIP archive.")
            return outputURL
        }

        if request.action.id == "zip_extract" || (srcExt == "zip" && request.action.category == .extract) {
            progressHandler(0.3, "Extracting archive safely (Zip Slip protection)...")
            let outDir = outputURL.pathExtension.isEmpty ? outputURL : outputURL.deletingPathExtension()
            _ = try DeveloperUtilities.extractArchiveSafely(archiveURL: request.sourceURL, destinationDirectory: outDir)
            progressHandler(1.0, "Extracted archive safely.")
            return outDir
        }

        if request.action.id == "hash_sha256" {
            progressHandler(0.3, "Calculating SHA-256 hash...")
            let hash = try DeveloperUtilities.calculateSHA256(for: request.sourceURL)
            let outText = "\(hash)  \(request.sourceURL.lastPathComponent)\n"
            try outText.write(to: outputURL, atomically: true, encoding: .utf8)
            progressHandler(1.0, "Calculated SHA-256: \(hash.prefix(12))...")
            return outputURL
        }

        if request.action.id == "base64_encode" {
            progressHandler(0.3, "Encoding file to Base64...")
            let b64 = try DeveloperUtilities.encodeBase64(fileURL: request.sourceURL)
            try b64.write(to: outputURL, atomically: true, encoding: .utf8)
            progressHandler(1.0, "Encoded file to Base64.")
            return outputURL
        }

        if request.action.id == "base64_decode" {
            progressHandler(0.3, "Decoding Base64 to binary...")
            let b64Str = try String(contentsOf: request.sourceURL)
            try DeveloperUtilities.decodeBase64(base64String: b64Str, outputURL: outputURL)
            progressHandler(1.0, "Decoded Base64 file.")
            return outputURL
        }

        if request.action.id == "json_format" {
            progressHandler(0.3, "Formatting & validating JSON...")
            let str = try String(contentsOf: request.sourceURL)
            let formatted = try DeveloperUtilities.formatJSON(jsonString: str)
            try formatted.write(to: outputURL, atomically: true, encoding: .utf8)
            progressHandler(1.0, "Formatted JSON.")
            return outputURL
        }

        if request.action.id == "json_to_yaml" {
            progressHandler(0.3, "Converting JSON to YAML...")
            let str = try String(contentsOf: request.sourceURL)
            let yaml = try DeveloperUtilities.jsonToYAML(jsonString: str)
            try yaml.write(to: outputURL, atomically: true, encoding: .utf8)
            progressHandler(1.0, "Converted JSON to YAML.")
            return outputURL
        }

        if request.action.id == "yaml_to_json" {
            progressHandler(0.3, "Converting YAML to JSON...")
            let str = try String(contentsOf: request.sourceURL)
            let json = try DeveloperUtilities.yamlToJSON(yamlString: str)
            try json.write(to: outputURL, atomically: true, encoding: .utf8)
            progressHandler(1.0, "Converted YAML to JSON.")
            return outputURL
        }

        // 1. CSV to JSON
        if (srcExt == "csv") && (targetExt == "json") {
            progressHandler(0.3, "Parsing CSV tabular data...")
            let csvData = try Data(contentsOf: request.sourceURL)
            guard let csvString = String(data: csvData, encoding: .utf8) ?? String(data: csvData, encoding: .ascii) else {
                throw ShiftKitError.conversionFailed(reason: "Unable to read CSV text content.")
            }
            let jsonString = try convertCSVToJSON(csvString: csvString)
            try jsonString.write(to: outputURL, atomically: true, encoding: .utf8)
            progressHandler(1.0, "Converted CSV to formatted JSON.")
            return outputURL
        }

        // 2. JSON to CSV
        if (srcExt == "json") && (targetExt == "csv") {
            progressHandler(0.3, "Parsing JSON array...")
            let jsonData = try Data(contentsOf: request.sourceURL)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw ShiftKitError.conversionFailed(reason: "Unable to read JSON text.")
            }
            let csvString = try convertJSONToCSV(jsonString: jsonString)
            try csvString.write(to: outputURL, atomically: true, encoding: .utf8)
            progressHandler(1.0, "Converted JSON to CSV table.")
            return outputURL
        }

        // 3. Markdown conversions
        if srcExt == "md" || srcExt == "markdown" {
            let mdData = try Data(contentsOf: request.sourceURL)
            guard let mdText = String(data: mdData, encoding: .utf8) else {
                throw ShiftKitError.conversionFailed(reason: "Unable to read Markdown text.")
            }

            if targetExt == "html" {
                progressHandler(0.4, "Rendering Markdown to HTML...")
                let html = renderMarkdownToHTML(mdText, title: request.sourceURL.deletingPathExtension().lastPathComponent)
                try html.write(to: outputURL, atomically: true, encoding: .utf8)
                progressHandler(1.0, "Converted Markdown to HTML.")
                return outputURL
            }

            if targetExt == "txt" {
                progressHandler(0.4, "Stripping Markdown formatting...")
                let stripped = stripMarkdown(mdText)
                try stripped.write(to: outputURL, atomically: true, encoding: .utf8)
                progressHandler(1.0, "Converted Markdown to Plain Text.")
                return outputURL
            }

            if targetExt == "pdf" || targetExt == "rtf" || targetExt == "docx" {
                progressHandler(0.3, "Parsing Markdown document...")
                let html = renderMarkdownToHTML(mdText, title: request.sourceURL.deletingPathExtension().lastPathComponent)
                let tempHTML = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".html")
                try html.write(to: tempHTML, atomically: true, encoding: .utf8)
                defer { try? FileManager.default.removeItem(at: tempHTML) }

                if targetExt == "pdf" {
                    return try convertHTMLToPDF(sourceHTMLURL: tempHTML, outputURL: outputURL, progressHandler: progressHandler)
                } else {
                    return try runTextUtil(sourceURL: tempHTML, targetFormat: targetExt, outputURL: outputURL, progressHandler: progressHandler)
                }
            }
        }

        // 4. Document to PDF via CoreText pagination
        if targetExt == "pdf" {
            if srcExt == "html" || srcExt == "htm" {
                return try convertHTMLToPDF(sourceHTMLURL: request.sourceURL, outputURL: outputURL, progressHandler: progressHandler)
            } else if srcExt == "rtf" || srcExt == "rtfd" || srcExt == "txt" || srcExt == "docx" || srcExt == "odt" {
                return try convertDocumentToPDF(sourceURL: request.sourceURL, outputURL: outputURL, progressHandler: progressHandler)
            } else if srcExt == "csv" {
                let csvData = try Data(contentsOf: request.sourceURL)
                let csvString = String(data: csvData, encoding: .utf8) ?? ""
                let html = renderCSVToHTML(csvString, title: request.sourceURL.deletingPathExtension().lastPathComponent)
                let tempHTML = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".html")
                try html.write(to: tempHTML, atomically: true, encoding: .utf8)
                defer { try? FileManager.default.removeItem(at: tempHTML) }
                return try convertHTMLToPDF(sourceHTMLURL: tempHTML, outputURL: outputURL, progressHandler: progressHandler)
            }
        }

        // 5. Native TextUtil Conversions (RTF, HTML, TXT, DOCX, ODT)
        let textUtilFormats = ["rtf", "rtfd", "html", "htm", "txt", "docx", "doc", "odt"]
        if textUtilFormats.contains(srcExt) && textUtilFormats.contains(targetExt) {
            let normalizedTarget = targetExt == "htm" ? "html" : (targetExt == "doc" ? "docx" : targetExt)
            return try runTextUtil(sourceURL: request.sourceURL, targetFormat: normalizedTarget, outputURL: outputURL, progressHandler: progressHandler)
        }

        // 6. External Engine for PPTX, XLSX, etc. (Requires LibreOffice or Pandoc)
        if ["pptx", "xlsx", "odt"].contains(srcExt) || ["pptx", "xlsx"].contains(targetExt) {
            if let soffice = Self.libreOfficePath {
                return try runLibreOffice(sofficePath: soffice, sourceURL: request.sourceURL, targetFormat: targetExt, outputURL: outputURL, progressHandler: progressHandler)
            } else if let pandoc = Self.pandocPath {
                return try runPandoc(pandocPath: pandoc, sourceURL: request.sourceURL, targetFormat: targetExt, outputURL: outputURL, progressHandler: progressHandler)
            } else {
                throw ShiftKitError.conversionFailed(
                    reason: "Conversion between \(srcExt.uppercased()) and \(targetExt.uppercased()) requires LibreOffice or Pandoc installed locally. Neither was found."
                )
            }
        }

        throw ShiftKitError.unsupportedAction("Conversion from \(srcExt.uppercased()) to \(targetExt.uppercased()) is not supported.")
    }

    // MARK: - CoreText / AttributedString PDF Rendering

    public func convertDocumentToPDF(
        sourceURL: URL,
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        progressHandler?(0.2, "Loading rich text document...")

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        var documentAttributes: NSDictionary?
        guard let attrString = try? NSAttributedString(url: sourceURL, options: options, documentAttributes: &documentAttributes) else {
            let tempRTF = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".rtf")
            defer { try? FileManager.default.removeItem(at: tempRTF) }
            _ = try runTextUtil(sourceURL: sourceURL, targetFormat: "rtf", outputURL: tempRTF)

            guard let fallbackAttr = try? NSAttributedString(url: tempRTF, options: options, documentAttributes: nil) else {
                throw ShiftKitError.conversionFailed(reason: "Could not parse document structure for PDF pagination.")
            }
            return try renderAttributedStringToPDF(fallbackAttr, outputURL: outputURL, progressHandler: progressHandler)
        }

        return try renderAttributedStringToPDF(attrString, outputURL: outputURL, progressHandler: progressHandler)
    }

    public func convertHTMLToPDF(
        sourceHTMLURL: URL,
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        progressHandler?(0.2, "Parsing HTML styling and structure...")

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        guard let attrString = try? NSAttributedString(url: sourceHTMLURL, options: options, documentAttributes: nil) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to parse HTML for PDF layout.")
        }

        return try renderAttributedStringToPDF(attrString, outputURL: outputURL, progressHandler: progressHandler)
    }

    private func renderAttributedStringToPDF(
        _ attrString: NSAttributedString,
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        progressHandler?(0.5, "Paginating document pages...")

        let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
        var pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Standard US Letter

        guard let consumer = CGDataConsumer(url: outputURL as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: &pageRect, nil) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to initialize PDF render context.")
        }

        let margin: CGFloat = 54.0 // 0.75 inch margins
        let textBounds = CGRect(
            x: margin,
            y: margin,
            width: pageRect.width - margin * 2,
            height: pageRect.height - margin * 2
        )

        var textRange = CFRange(location: 0, length: 0)
        let totalLength = attrString.length
        var pageNumber = 1

        while textRange.location < totalLength {
            context.beginPage(mediaBox: &pageRect)

            let path = CGPath(rect: textBounds, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, textRange, path, nil)

            context.saveGState()
            context.translateBy(x: 0, y: pageRect.height)
            context.scaleBy(x: 1.0, y: -1.0)
            CTFrameDraw(frame, context)
            context.restoreGState()

            context.endPage()

            let frameRange = CTFrameGetVisibleStringRange(frame)
            if frameRange.length == 0 {
                break
            }
            textRange.location += frameRange.length
            pageNumber += 1

            let frac = 0.5 + (Double(textRange.location) / Double(max(1, totalLength))) * 0.45
            progressHandler?(frac, "Formatted page \(pageNumber)...")
        }

        context.closePDF()
        progressHandler?(1.0, "Saved \(pageNumber - 1) pages to PDF.")
        return outputURL
    }

    // MARK: - Native TextUtil Runner

    private func runTextUtil(
        sourceURL: URL,
        targetFormat: String,
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        progressHandler?(0.3, "Converting document via native text engine...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
        process.arguments = [
            "-convert", targetFormat,
            "-output", outputURL.path,
            sourceURL.path
        ]

        let errPipe = Pipe()
        process.standardError = errPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw ShiftKitError.conversionFailed(reason: "Failed to launch textutil: \(error.localizedDescription)")
        }

        if process.terminationStatus != 0 {
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errStr = String(data: errData, encoding: .utf8) ?? "Unknown error"
            throw ShiftKitError.conversionFailed(reason: "textutil failed with status \(process.terminationStatus): \(errStr)")
        }

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ShiftKitError.conversionFailed(reason: "Output file was not created by textutil.")
        }

        progressHandler?(1.0, "Completed document conversion to \(targetFormat.uppercased()).")
        return outputURL
    }

    // MARK: - External Engine Runners

    private func runLibreOffice(
        sofficePath: String,
        sourceURL: URL,
        targetFormat: String,
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        progressHandler?(0.2, "Executing conversion with LibreOffice headless...")

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: sofficePath)
        process.arguments = [
            "--headless",
            "--convert-to", targetFormat,
            "--outdir", tempDir.path,
            sourceURL.path
        ]

        let errPipe = Pipe()
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errStr = String(data: errData, encoding: .utf8) ?? "Unknown error"
            throw ShiftKitError.conversionFailed(reason: "LibreOffice failed: \(errStr)")
        }

        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let generated = tempDir.appendingPathComponent("\(baseName).\(targetFormat)")

        guard FileManager.default.fileExists(atPath: generated.path) else {
            throw ShiftKitError.conversionFailed(reason: "LibreOffice did not generate expected output file.")
        }

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        try FileManager.default.moveItem(at: generated, to: outputURL)

        progressHandler?(1.0, "Converted via LibreOffice.")
        return outputURL
    }

    private func runPandoc(
        pandocPath: String,
        sourceURL: URL,
        targetFormat: String,
        outputURL: URL,
        progressHandler: (@Sendable (Double?, String) -> Void)? = nil
    ) throws -> URL {
        progressHandler?(0.2, "Executing conversion with Pandoc...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: pandocPath)
        process.arguments = [
            sourceURL.path,
            "-o", outputURL.path
        ]

        let errPipe = Pipe()
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errStr = String(data: errData, encoding: .utf8) ?? "Unknown error"
            throw ShiftKitError.conversionFailed(reason: "Pandoc failed: \(errStr)")
        }

        progressHandler?(1.0, "Converted via Pandoc.")
        return outputURL
    }

    // MARK: - CSV & JSON Parsing & Transformation

    public func convertCSVToJSON(csvString: String) throws -> String {
        let lines = parseCSVRows(csvString)
        guard let headerRow = lines.first, !headerRow.isEmpty else {
            throw ShiftKitError.conversionFailed(reason: "CSV file is empty or lacks headers.")
        }

        var results: [[String: String]] = []
        for row in lines.dropFirst() {
            guard !row.isEmpty else { continue }
            var item: [String: String] = [:]
            for (idx, header) in headerRow.enumerated() {
                let value = idx < row.count ? row[idx] : ""
                item[header] = value
            }
            results.append(item)
        }

        let data = try JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys])
        guard let string = String(data: data, encoding: .utf8) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to encode JSON string.")
        }
        return string
    }

    public func convertJSONToCSV(jsonString: String) throws -> String {
        guard let data = jsonString.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw ShiftKitError.conversionFailed(reason: "Input JSON must be an array of objects to convert to CSV.")
        }

        guard !jsonArray.isEmpty else {
            return ""
        }

        var keySet = Set<String>()
        var headers: [String] = []
        for dict in jsonArray {
            for key in dict.keys {
                if !keySet.contains(key) {
                    keySet.insert(key)
                    headers.append(key)
                }
            }
        }

        var csvLines: [String] = []
        csvLines.append(headers.map { escapeCSVValue($0) }.joined(separator: ","))

        for dict in jsonArray {
            let row = headers.map { key -> String in
                if let val = dict[key] {
                    return escapeCSVValue("\(val)")
                }
                return ""
            }
            csvLines.append(row.joined(separator: ","))
        }

        return csvLines.joined(separator: "\n")
    }

    private func parseCSVRows(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false

        let chars = Array(text)
        var i = 0

        while i < chars.count {
            let char = chars[i]

            if insideQuotes {
                if char == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 1
                    } else {
                        insideQuotes = false
                    }
                } else {
                    currentField.append(char)
                }
            } else {
                if char == "\"" {
                    insideQuotes = true
                } else if char == "," {
                    currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                    currentField = ""
                } else if char == "\r" {
                } else if char == "\n" {
                    currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                    currentField = ""
                    if !currentRow.isEmpty && !(currentRow.count == 1 && currentRow[0].isEmpty) {
                        rows.append(currentRow)
                    }
                    currentRow = []
                } else {
                    currentField.append(char)
                }
            }
            i += 1
        }

        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
            rows.append(currentRow)
        }

        return rows
    }

    private func escapeCSVValue(_ val: String) -> String {
        if val.contains(",") || val.contains("\"") || val.contains("\n") || val.contains("\r") {
            let escaped = val.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"" + escaped + "\""
        }
        return val
    }

    // MARK: - Markdown Helpers

    public func renderMarkdownToHTML(_ md: String, title: String) -> String {
        var htmlBody = ""
        let lines = md.components(separatedBy: .newlines)
        var insideCodeBlock = false
        var insideList = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.starts(with: "```") {
                if insideCodeBlock {
                    htmlBody += "</code></pre>\n"
                    insideCodeBlock = false
                } else {
                    if insideList {
                        htmlBody += "</ul>\n"
                        insideList = false
                    }
                    htmlBody += "<pre style=\"background: #F3EEE4; padding: 12px; border-radius: 6px; font-family: monospace; font-size: 13px;\"><code>"
                    insideCodeBlock = true
                }
                continue
            }

            if insideCodeBlock {
                htmlBody += escapeHTML(line) + "\n"
                continue
            }

            if trimmed.starts(with: "- ") || trimmed.starts(with: "* ") {
                if !insideList {
                    htmlBody += "<ul style=\"line-height: 1.6;\">\n"
                    insideList = true
                }
                let item = String(trimmed.dropFirst(2))
                htmlBody += "  <li>\(formatInlineMarkdown(item))</li>\n"
                continue
            } else {
                if insideList {
                    htmlBody += "</ul>\n"
                    insideList = false
                }
            }

            if trimmed.starts(with: "### ") {
                htmlBody += "<h3 style=\"color: #34312D; font-size: 16px; margin-top: 16px;\">\(formatInlineMarkdown(String(trimmed.dropFirst(4))))</h3>\n"
            } else if trimmed.starts(with: "## ") {
                htmlBody += "<h2 style=\"color: #34312D; font-size: 20px; margin-top: 20px;\">\(formatInlineMarkdown(String(trimmed.dropFirst(3))))</h2>\n"
            } else if trimmed.starts(with: "# ") {
                htmlBody += "<h1 style=\"color: #34312D; font-size: 26px; border-bottom: 2px solid #E5D8C7; padding-bottom: 8px;\">\(formatInlineMarkdown(String(trimmed.dropFirst(2))))</h1>\n"
            } else if trimmed.starts(with: "> ") {
                htmlBody += "<blockquote style=\"border-left: 4px solid #D98768; margin: 12px 0; padding-left: 12px; color: #465343; font-style: italic;\">\(formatInlineMarkdown(String(trimmed.dropFirst(2))))</blockquote>\n"
            } else if trimmed.isEmpty {
                htmlBody += "<br/>\n"
            } else {
                htmlBody += "<p style=\"color: #34312D; line-height: 1.6; font-size: 14px; margin: 6px 0;\">\(formatInlineMarkdown(line))</p>\n"
            }
        }

        if insideList { htmlBody += "</ul>\n" }
        if insideCodeBlock { htmlBody += "</code></pre>\n" }

        return "<!DOCTYPE html><html><head><meta charset=\"utf-8\"><title>" + escapeHTML(title) + "</title><style>body { font-family: -apple-system, sans-serif; background-color: #FAF8F3; color: #34312D; max-width: 800px; margin: 40px auto; padding: 24px; }</style></head><body>" + htmlBody + "</body></html>"
    }

    public func renderCSVToHTML(_ csv: String, title: String) -> String {
        let rows = parseCSVRows(csv)
        var tableHTML = "<table style=\"width: 100%; border-collapse: collapse; font-size: 13px; text-align: left;\">\n"

        if let headers = rows.first {
            tableHTML += "  <thead><tr style=\"background: #F3EEE4; border-bottom: 2px solid #E5D8C7;\">"
            for h in headers {
                tableHTML += "<th style=\"padding: 8px 12px; color: #34312D;\">\(escapeHTML(h))</th>"
            }
            tableHTML += "</tr></thead>\n"
        }

        tableHTML += "  <tbody>\n"
        for row in rows.dropFirst() {
            tableHTML += "  <tr style=\"border-bottom: 1px solid #E5D8C7;\">"
            for cell in row {
                tableHTML += "<td style=\"padding: 8px 12px; color: #34312D;\">\(escapeHTML(cell))</td>"
            }
            tableHTML += "</tr>\n"
        }
        tableHTML += "  </tbody></table>"

        return "<!DOCTYPE html><html><head><meta charset=\"utf-8\"><title>" + escapeHTML(title) + "</title><style>body { font-family: -apple-system, sans-serif; background: #FAF8F3; color: #34312D; padding: 24px; }</style></head><body><h2 style=\"color: #34312D; border-bottom: 2px solid #E5D8C7; padding-bottom: 8px;\">" + escapeHTML(title) + "</h2>" + tableHTML + "</body></html>"
    }

    private func formatInlineMarkdown(_ text: String) -> String {
        var escaped = escapeHTML(text)

        let boldPattern = "\\*\\*(.+?)\\*\\*"
        escaped = escaped.replacingOccurrences(of: boldPattern, with: "<strong>$1</strong>", options: .regularExpression)

        let italicPattern = "(?<!\\*)\\*([^*]+?)\\*(?!\\*)"
        escaped = escaped.replacingOccurrences(of: italicPattern, with: "<em>$1</em>", options: .regularExpression)

        let codePattern = "`([^`]+?)`"
        escaped = escaped.replacingOccurrences(of: codePattern, with: "<code style=\"background: #F3EEE4; padding: 2px 4px; border-radius: 4px; font-family: monospace;\">$1</code>", options: .regularExpression)

        return escaped
    }

    private func stripMarkdown(_ md: String) -> String {
        var text = md
        text = text.replacingOccurrences(of: "```[\\s\\S]*?```", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "^#{1,6}\\s*", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\*\\*|\\*", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "^>\\s*", with: "", options: .regularExpression)
        return text
    }

    private func escapeHTML(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
