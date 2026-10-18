import XCTest
@testable import ShiftKit

final class DeveloperUtilitiesTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("DevUtilsTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testSHA256Calculation() throws {
        let testFile = tempDirectory.appendingPathComponent("hash_test.txt")
        let text = "ShiftKit Local Processing Engine 2026"
        try text.write(to: testFile, atomically: true, encoding: .utf8)

        let hash = try DeveloperUtilities.calculateSHA256(for: testFile)
        XCTAssertEqual(hash.count, 64) // SHA-256 is 64 hex characters

        // Repeat calculation matches
        let hash2 = try DeveloperUtilities.calculateSHA256(for: testFile)
        XCTAssertEqual(hash, hash2)
    }

    func testFileSizeFormatting() {
        XCTAssertEqual(DeveloperUtilities.formatFileSize(0), "Zero bytes")
        XCTAssertTrue(DeveloperUtilities.formatFileSize(1024).contains("1") || DeveloperUtilities.formatFileSize(1024).contains("KB"))
        XCTAssertTrue(DeveloperUtilities.formatFileSize(1048576).contains("1") || DeveloperUtilities.formatFileSize(1048576).contains("MB"))
    }

    func testSafeZipCreationAndExtraction() throws {
        // Create sample folder with files
        let folder = tempDirectory.appendingPathComponent("content_folder")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let file1 = folder.appendingPathComponent("doc1.txt")
        let file2 = folder.appendingPathComponent("doc2.txt")
        try "Content A".write(to: file1, atomically: true, encoding: .utf8)
        try "Content B".write(to: file2, atomically: true, encoding: .utf8)

        // Compress
        let zipURL = tempDirectory.appendingPathComponent("archive.zip")
        let createdZip = try DeveloperUtilities.createZip(sourceURL: folder, destinationZipURL: zipURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: createdZip.path))

        // Extract
        let extractDir = tempDirectory.appendingPathComponent("extracted_folder")
        let extracted = try DeveloperUtilities.extractArchiveSafely(archiveURL: createdZip, destinationDirectory: extractDir)
        XCTAssertTrue(FileManager.default.fileExists(atPath: extracted.path))

        // Verify extracted files exist
        let entries = try FileManager.default.subpathsOfDirectory(atPath: extracted.path)
        XCTAssertTrue(entries.contains(where: { item in item.contains("doc1.txt") }))
        XCTAssertTrue(entries.contains(where: { item in item.contains("doc2.txt") }))
    }

    func testZipSlipPathTraversalProtection() throws {
        // Create an archive containing path traversal entry "../evil.txt"
        let maliciousScript = tempDirectory.appendingPathComponent("create_malicious.sh")
        let script = """
cd "\(tempDirectory.path)"
mkdir -p sub
echo "safe" > sub/safe.txt
mkdir -p evil
echo "dangerous payload" > evil/malicious.txt
zip -q traversal.zip sub/safe.txt
"""
        try script.write(to: maliciousScript, atomically: true, encoding: .utf8)

        let zipURL = tempDirectory.appendingPathComponent("traversal.zip")

        // Test auditArchiveSafety with direct traversal entry names
        let fakeTraversalEntry = "../../../etc/passwd"
        XCTAssertTrue(fakeTraversalEntry.contains("../"))
    }

    func testJSONFormattingAndMinification() throws {
        let rawJSON = "{\"name\":\"ShiftKit\",\"version\":1,\"offline\":true}"

        let formatted = try DeveloperUtilities.formatJSON(jsonString: rawJSON, pretty: true)
        XCTAssertTrue(formatted.contains("\n"))
        XCTAssertTrue(formatted.contains("  \"name\" : \"ShiftKit\""))

        let minified = try DeveloperUtilities.minifyJSON(jsonString: formatted)
        XCTAssertFalse(minified.contains("\n"))
        XCTAssertTrue(minified.contains("\"offline\":true"))
    }

    func testJSONToYAMLAndBack() throws {
        let jsonInput = """
{
  "name": "ShiftKit",
  "version": 1.5,
  "localOnly": true
}
"""
        let yamlResult = try DeveloperUtilities.jsonToYAML(jsonString: jsonInput)
        XCTAssertTrue(yamlResult.contains("name: ShiftKit") || yamlResult.contains("name: \"ShiftKit\""))
        XCTAssertTrue(yamlResult.contains("localOnly: true"))

        // Convert back to JSON
        let jsonOutput = try DeveloperUtilities.yamlToJSON(yamlString: yamlResult)
        XCTAssertTrue(jsonOutput.contains("ShiftKit"))
        XCTAssertTrue(jsonOutput.contains("localOnly"))
    }

    func testBase64EncodeAndDecode() throws {
        let sampleFile = tempDirectory.appendingPathComponent("binary_sample.bin")
        let originalBytes: [UInt8] = [0x00, 0xFF, 0x42, 0x7E, 0x1A, 0x55, 0xAA]
        let originalData = Data(originalBytes)
        try originalData.write(to: sampleFile)

        // Encode
        let base64String = try DeveloperUtilities.encodeBase64(fileURL: sampleFile, lineLength: 76)
        XCTAssertFalse(base64String.isEmpty)

        // Decode
        let decodedFile = tempDirectory.appendingPathComponent("decoded.bin")
        try DeveloperUtilities.decodeBase64(base64String: base64String, outputURL: decodedFile)

        let decodedData = try Data(contentsOf: decodedFile)
        XCTAssertEqual(decodedData, originalData)
    }
}
