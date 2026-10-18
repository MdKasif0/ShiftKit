import XCTest
import PDFKit
@testable import ShiftKit

final class DocumentConversionTests: XCTestCase {
    var engine: DocumentConversionEngine!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        engine = DocumentConversionEngine()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("DocTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    private func createSampleRTF() -> URL {
        let rtfURL = tempDirectory.appendingPathComponent("sample.rtf")
        let rtfContent = "{\\rtf1\\ansi\\deff0{\\fonttbl{\\f0 Helvetica;}}\\f0\\b ShiftKit Document Engine\\b0\\par This is a local-first test document.\\par}"
        try? rtfContent.write(to: rtfURL, atomically: true, encoding: .ascii)
        return rtfURL
    }

    func testNativeRTFToDOCXAndHTML() async throws {
        let rtfURL = createSampleRTF()

        // 1. RTF to DOCX
        let docxURL = tempDirectory.appendingPathComponent("output.docx")
        let req1 = ConversionRequest(
            sourceURL: rtfURL,
            fileType: .document(.rtf),
            action: ConversionAction(id: "doc_to_docx", title: "To Word", subtitle: "", systemIcon: "doc", category: .convert, targetFormat: "docx"),
            destinationURL: docxURL
        )
        let res1 = try await engine.execute(request: req1, outputURL: docxURL) { _, _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: res1.path))

        // 2. RTF to HTML
        let htmlURL = tempDirectory.appendingPathComponent("output.html")
        let req2 = ConversionRequest(
            sourceURL: rtfURL,
            fileType: .document(.rtf),
            action: ConversionAction(id: "doc_to_html", title: "To HTML", subtitle: "", systemIcon: "globe", category: .convert, targetFormat: "html"),
            destinationURL: htmlURL
        )
        let res2 = try await engine.execute(request: req2, outputURL: htmlURL) { _, _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: res2.path))

        let htmlString = try String(contentsOf: res2)
        XCTAssertTrue(htmlString.contains("ShiftKit Document Engine") || htmlString.contains("Helvetica"))
    }

    func testDocumentToPDFRendering() throws {
        let rtfURL = createSampleRTF()
        let pdfURL = tempDirectory.appendingPathComponent("rtf_output.pdf")

        let result = try engine.convertDocumentToPDF(sourceURL: rtfURL, outputURL: pdfURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))

        guard let doc = PDFDocument(url: result) else {
            XCTFail("Rendered PDF could not be opened")
            return
        }
        XCTAssertGreaterThanOrEqual(doc.pageCount, 1)
    }

    func testMarkdownToHTMLAndTXT() async throws {
        let md = """
# ShiftKit Architecture
A **warm** and *fast* macOS utility.

## Features
- Local-first execution
- Circular radial action menu
- Zero server dependencies

> Privacy is not an afterthought.
"""
        let html = engine.renderMarkdownToHTML(md, title: "ShiftKit Architecture")
        XCTAssertTrue(html.contains("<h1"))
        XCTAssertTrue(html.contains("<strong>warm</strong>"))
        XCTAssertTrue(html.contains("<em>fast</em>"))
        XCTAssertTrue(html.contains("<li>Local-first execution</li>"))
        XCTAssertTrue(html.contains("<blockquote"))

        // Markdown to PDF execution
        let mdURL = tempDirectory.appendingPathComponent("test.md")
        try md.write(to: mdURL, atomically: true, encoding: .utf8)

        let pdfURL = tempDirectory.appendingPathComponent("md_out.pdf")
        let req = ConversionRequest(
            sourceURL: mdURL,
            fileType: .document(.markdown),
            action: ConversionAction(id: "md_to_pdf", title: "To PDF", subtitle: "", systemIcon: "doc", category: .convert, targetFormat: "pdf"),
            destinationURL: pdfURL
        )
        let result = try await engine.execute(request: req, outputURL: pdfURL) { _, _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }

    func testCSVToJSONAndBack() throws {
        let csvContent = """
name,role,department
Alice,Lead Engineer,Platform
Bob,"Senior Designer, Product",Design
Charlie,Core Developer,Security
"""
        let jsonResult = try engine.convertCSVToJSON(csvString: csvContent)
        XCTAssertTrue(jsonResult.contains("Alice"))
        XCTAssertTrue(jsonResult.contains("Lead Engineer"))
        XCTAssertTrue(jsonResult.contains("Senior Designer, Product"))

        // Convert back to CSV
        let csvResult = try engine.convertJSONToCSV(jsonString: jsonResult)
        XCTAssertTrue(csvResult.contains("Alice"))
        XCTAssertTrue(csvResult.contains("Senior Designer, Product"))
    }

    func testCSVToHTMLTableAndPDF() async throws {
        let csvContent = """
ID,Status,Duration
001,Active,2.5s
002,Completed,1.2s
"""
        let csvURL = tempDirectory.appendingPathComponent("test.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)

        let pdfURL = tempDirectory.appendingPathComponent("csv_table.pdf")
        let req = ConversionRequest(
            sourceURL: csvURL,
            fileType: .document(.csv),
            action: ConversionAction(id: "csv_to_pdf", title: "To PDF", subtitle: "", systemIcon: "doc", category: .convert, targetFormat: "pdf"),
            destinationURL: pdfURL
        )
        let result = try await engine.execute(request: req, outputURL: pdfURL) { _, _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }
}
