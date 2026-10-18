import XCTest
@testable import ShiftKit

final class MergeWorkflowTests: XCTestCase {
    var registry: ConversionRegistry!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        registry = ConversionRegistry.shared
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("MergeTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    private func createDummyFile(name: String) -> URL {
        let url = tempDirectory.appendingPathComponent(name)
        try? "dummy content".write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func testPDFMergeValidation() {
        let pdf1 = InspectedFile(url: createDummyFile(name: "doc1.pdf"), fileType: .pdf, metadata: FileMetadata(fileSize: 100, fileExtension: "pdf"))
        let pdf2 = InspectedFile(url: createDummyFile(name: "doc2.pdf"), fileType: .pdf, metadata: FileMetadata(fileSize: 200, fileExtension: "pdf"))

        let result = registry.validateMerge(files: [pdf1, pdf2], targetFormat: .pdf)
        XCTAssertTrue(result.canMerge)
        XCTAssertEqual(result.compatibleFiles.count, 2)
    }

    func testAudioMergeValidation() {
        let aud1 = InspectedFile(url: createDummyFile(name: "track1.mp3"), fileType: .audio(.mp3), metadata: FileMetadata(fileSize: 100, fileExtension: "mp3"))
        let aud2 = InspectedFile(url: createDummyFile(name: "track2.mp3"), fileType: .audio(.mp3), metadata: FileMetadata(fileSize: 200, fileExtension: "mp3"))

        let result = registry.validateMerge(files: [aud1, aud2], targetFormat: .mp3)
        XCTAssertTrue(result.canMerge)
    }

    func testVideoMergeValidation() {
        let vid1 = InspectedFile(url: createDummyFile(name: "clip1.mp4"), fileType: .video(.mp4), metadata: FileMetadata(fileSize: 100, fileExtension: "mp4"))
        let vid2 = InspectedFile(url: createDummyFile(name: "clip2.mp4"), fileType: .video(.mp4), metadata: FileMetadata(fileSize: 200, fileExtension: "mp4"))

        let result = registry.validateMerge(files: [vid1, vid2], targetFormat: .mp4)
        XCTAssertTrue(result.canMerge)
    }

    func testIncompatibleMergeRejection() {
        let pdf = InspectedFile(url: createDummyFile(name: "doc.pdf"), fileType: .pdf, metadata: FileMetadata(fileSize: 100, fileExtension: "pdf"))
        let vid = InspectedFile(url: createDummyFile(name: "clip.mp4"), fileType: .video(.mp4), metadata: FileMetadata(fileSize: 200, fileExtension: "mp4"))

        let result = registry.validateMerge(files: [pdf, vid], targetFormat: .pdf)
        XCTAssertFalse(result.canMerge)
        XCTAssertFalse(result.incompatibleFiles.isEmpty)
    }
}
