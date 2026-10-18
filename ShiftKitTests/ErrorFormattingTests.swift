import XCTest
@testable import ShiftKit

final class ErrorFormattingTests: XCTestCase {

    func testUserFacingDescriptionsAreNonTechnicalAndClean() {
        let sampleURL = URL(fileURLWithPath: "/Users/test/Documents/file.xyz")

        let errors: [ShiftKitError] = [
            .unsupportedFileType(sampleURL),
            .engineNotAvailable(engineName: "FFmpeg"),
            .invalidInput(reason: "Header damaged"),
            .permissionDenied(sampleURL),
            .insufficientDiskSpace(needed: 1_000_000_000, available: 100_000),
            .outputConflict(sampleURL),
            .corruptMedia(reason: "Image header was truncated"),
            .conversionFailed(reason: "Process exited unexpectedly"),
            .cancelled
        ]

        for err in errors {
            let desc = err.userFacingDescription
            let suggestion = err.recoverySuggestion

            // Must not be empty
            XCTAssertFalse(desc.isEmpty, "Description should not be empty for \(err)")
            XCTAssertFalse(suggestion.isEmpty, "Recovery suggestion should not be empty for \(err)")

            // Avoid raw CLI / process leakage in main user-facing banner
            XCTAssertFalse(desc.contains("/usr/local/bin"), "Should not leak absolute CLI path")
            XCTAssertFalse(desc.contains("exit code 1"), "Should not show raw exit code")
            XCTAssertFalse(desc.contains("SIGKILL"), "Should not show raw Unix signals")
        }
    }

    func testSpecificErrorDescriptions() {
        let denied = ShiftKitError.permissionDenied(URL(fileURLWithPath: "/restricted/path.pdf"))
        XCTAssertTrue(denied.userFacingDescription.contains("Access to \"path.pdf\" was denied"))
        XCTAssertTrue(denied.recoverySuggestion.contains("System Settings > Privacy & Security"))

        let conflict = ShiftKitError.outputConflict(URL(fileURLWithPath: "/tmp/existing.png"))
        XCTAssertTrue(conflict.userFacingDescription.contains("A file already exists at \"existing.png\""))
        XCTAssertTrue(conflict.recoverySuggestion.contains("Settings to Auto-number"))

        let space = ShiftKitError.insufficientDiskSpace(needed: 1024 * 1024 * 500, available: 1024 * 1024 * 50)
        XCTAssertTrue(space.userFacingDescription.contains("needs approximately"))
        XCTAssertTrue(space.recoverySuggestion.contains("Free up disk space"))

        let unsupported = ShiftKitError.unsupportedFileType(URL(fileURLWithPath: "/tmp/test.xyz"))
        XCTAssertTrue(unsupported.userFacingDescription.contains("test.xyz"))
        XCTAssertTrue(unsupported.recoverySuggestion.contains("Supported Formats in Settings"))
    }
}
