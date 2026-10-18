import XCTest
import UniformTypeIdentifiers
@testable import ShiftKit

final class FileAccessManagerTests: XCTestCase {
    private var manager: FileAccessManager!
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        manager = FileAccessManager()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testValidateSingleFile() {
        let fileURL = tempDirectory.appendingPathComponent("document.pdf")
        FileManager.default.createFile(atPath: fileURL.path, contents: "dummy pdf".data(using: .utf8))

        let result = manager.validateURLs([fileURL])
        switch result {
        case .success(let files):
            XCTAssertEqual(files.count, 1)
            XCTAssertEqual(files[0].fileName, "document.pdf")
            XCTAssertEqual(files[0].resolvedURL.path, fileURL.path)
            XCTAssertFalse(files[0].isSymbolicLink)
        case .failure(let error):
            XCTFail("Validation failed unexpectedly: \(error)")
        }
    }

    func testValidateMultipleFiles() {
        let file1 = tempDirectory.appendingPathComponent("photo1.jpg")
        let file2 = tempDirectory.appendingPathComponent("photo2.png")
        FileManager.default.createFile(atPath: file1.path, contents: "data1".data(using: .utf8))
        FileManager.default.createFile(atPath: file2.path, contents: "data2".data(using: .utf8))

        let result = manager.validateURLs([file1, file2])
        switch result {
        case .success(let files):
            XCTAssertEqual(files.count, 2)
            XCTAssertEqual(files[0].fileName, "photo1.jpg")
            XCTAssertEqual(files[1].fileName, "photo2.png")
        case .failure(let error):
            XCTFail("Validation failed unexpectedly: \(error)")
        }
    }

    func testValidateFilesWithSpacesAndUnicode() {
        // Space, German umlaut, and Korean characters
        let file1 = tempDirectory.appendingPathComponent("Quarterly Report Final (2026).pdf")
        let file2 = tempDirectory.appendingPathComponent("Schöne Straße Bild.png")
        let file3 = tempDirectory.appendingPathComponent("사진 파일.webp")

        FileManager.default.createFile(atPath: file1.path, contents: "pdf".data(using: .utf8))
        FileManager.default.createFile(atPath: file2.path, contents: "png".data(using: .utf8))
        FileManager.default.createFile(atPath: file3.path, contents: "webp".data(using: .utf8))

        let result = manager.validateURLs([file1, file2, file3])
        switch result {
        case .success(let files):
            XCTAssertEqual(files.count, 3)
            XCTAssertEqual(files[0].fileName, "Quarterly Report Final (2026).pdf")
            XCTAssertEqual(files[1].fileName, "Schöne Straße Bild.png")
            XCTAssertEqual(files[2].fileName, "사진 파일.webp")
        case .failure(let error):
            XCTFail("Validation failed with unicode/spaces: \(error)")
        }
    }

    func testRejectNonExistentFile() {
        let nonExistent = tempDirectory.appendingPathComponent("ghost_file.png")
        let result = manager.validateURLs([nonExistent])

        switch result {
        case .success:
            XCTFail("Expected failure for non-existent file.")
        case .failure(let error):
            if case .fileNotFound(let url) = error {
                XCTAssertEqual(url.lastPathComponent, "ghost_file.png")
            } else {
                XCTFail("Expected .fileNotFound error but got \(error)")
            }
        }
    }

    func testRejectDirectoryDrop() {
        let subDir = tempDirectory.appendingPathComponent("SubFolder")
        try? FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

        let result = manager.validateURLs([subDir])
        switch result {
        case .success:
            XCTFail("Expected failure when dropping directory.")
        case .failure(let error):
            if case .directoryUnsupported = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected .directoryUnsupported error but got \(error)")
            }
        }
    }

    func testSecurityRejectAppBundle() {
        let fakeApp = tempDirectory.appendingPathComponent("Malicious.app")
        FileManager.default.createFile(atPath: fakeApp.path, contents: "fake".data(using: .utf8))

        let result = manager.validateURLs([fakeApp])
        switch result {
        case .success:
            XCTFail("Expected security rejection for .app bundle.")
        case .failure(let error):
            if case .unsafeExecutable = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected .unsafeExecutable error but got \(error)")
            }
        }
    }

    func testSymlinkResolution() {
        let realFile = tempDirectory.appendingPathComponent("target_file.png")
        FileManager.default.createFile(atPath: realFile.path, contents: "png".data(using: .utf8))

        let symlink = tempDirectory.appendingPathComponent("symlink_file.png")
        try? FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: realFile)

        let result = manager.validateURLs([symlink])
        switch result {
        case .success(let files):
            XCTAssertEqual(files.count, 1)
            XCTAssertEqual(files[0].originalURL.lastPathComponent, "symlink_file.png")
            XCTAssertEqual(files[0].resolvedURL.lastPathComponent, "target_file.png")
            XCTAssertTrue(files[0].isSymbolicLink)
        case .failure(let error):
            XCTFail("Symlink resolution failed: \(error)")
        }
    }
}
