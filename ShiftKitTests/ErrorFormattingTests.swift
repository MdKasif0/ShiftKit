import XCTest
@testable import ShiftKit

final class ErrorFormattingTests: XCTestCase {

    func testAllSixteenErrorCasesProduceHumanFriendlyDescriptions() {
        let sampleURL = URL(fileURLWithPath: "/Users/test/Documents/file.xyz")

        let allErrors: [ShiftKitError] = [
            .fileNotFound(sampleURL),
            .unsupportedFileType(sampleURL),
            .unsupportedAction("arbitrary_action"),
            .engineNotAvailable(engineName: "FFmpeg"),
            .destinationUnwritable(sampleURL),
            .conversionFailed(reason: "Process exited unexpectedly"),
            .processExecutionFailed(exitCode: 1, message: "ffmpeg failed with code 1"),
            .cancelled,
            .unsupportedCodecOrFormat(codec: "av1", format: "mkv"),
            .insufficientDiskSpace(needed: 1_000_000_000, available: 100_000),
            .corruptMedia(reason: "Image header was truncated"),
            .invalidTimestamp(start: 10.0, end: 5.0, duration: 8.0),
            .incompatibleStreams(reason: "Mismatched dimensions"),
            .permissionDenied(sampleURL),
            .outputConflict(sampleURL),
            .invalidInput(reason: "Header damaged")
        ]

        XCTAssertEqual(allErrors.count, 16, "Should cover all 16 error cases")

        for err in allErrors {
            let desc = err.userFacingDescription
            let suggestion = err.recoverySuggestion

            XCTAssertFalse(desc.isEmpty, "Description should not be empty for \(err)")
            XCTAssertFalse(suggestion.isEmpty, "Recovery suggestion should not be empty for \(err)")

            // Avoid raw CLI / process leakage in main user-facing banner
            XCTAssertFalse(desc.contains("/usr/local/bin"), "Should not leak absolute CLI path")
            XCTAssertFalse(desc.contains("SIGKILL"), "Should not show raw Unix signals")
            XCTAssertFalse(desc.contains("/bin/sh"), "Should not leak shell binary")

            // Check localizedDescription matches userFacingDescription
            XCTAssertEqual(err.localizedDescription, desc)
        }
    }

    func testSpecificErrorDescriptions() {
        let denied = ShiftKitError.permissionDenied(URL(fileURLWithPath: "/restricted/path.pdf"))
        XCTAssertTrue(denied.userFacingDescription.contains("Access to "path.pdf" was denied"))
        XCTAssertTrue(denied.recoverySuggestion.contains("System Settings > Privacy & Security"))

        let conflict = ShiftKitError.outputConflict(URL(fileURLWithPath: "/tmp/existing.png"))
        XCTAssertTrue(conflict.userFacingDescription.contains("A file already exists at "existing.png""))
        XCTAssertTrue(conflict.recoverySuggestion.contains("Settings to Auto-number"))

        let space = ShiftKitError.insufficientDiskSpace(needed: 1024 * 1024 * 500, available: 1024 * 1024 * 50)
        XCTAssertTrue(space.userFacingDescription.contains("needs approximately"))
        XCTAssertTrue(space.recoverySuggestion.contains("Free up disk space"))

        let unsupported = ShiftKitError.unsupportedFileType(URL(fileURLWithPath: "/tmp/test.xyz"))
        XCTAssertTrue(unsupported.userFacingDescription.contains("test.xyz"))
        XCTAssertTrue(unsupported.recoverySuggestion.contains("Supported Formats in Settings"))

        let missing = ShiftKitError.fileNotFound(URL(fileURLWithPath: "/tmp/ghost.png"))
        XCTAssertTrue(missing.userFacingDescription.contains("ghost.png"))
        XCTAssertTrue(missing.recoverySuggestion.contains("Verify that the file still exists"))
    }
}
