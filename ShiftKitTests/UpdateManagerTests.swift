import XCTest
@testable import ShiftKit

@MainActor
final class UpdateManagerTests: XCTestCase {
    private var updateManager: UpdateManager!

    override func setUp() async throws {
        try await super.setUp()
        self.updateManager = UpdateManager.shared
        self.updateManager.resetState()
    }

    override func tearDown() async throws {
        self.updateManager.resetState()
        try await super.tearDown()
    }

    func testUpdateManagerInitializationAndReadiness() {
        XCTAssertTrue(updateManager.isReady, "UpdateManager should be initialized and ready")
        XCTAssertEqual(updateManager.state, .idle)
    }

    func testVersionAndBuildInformation() {
        XCTAssertFalse(updateManager.currentVersion.isEmpty)
        XCTAssertFalse(updateManager.currentBuild.isEmpty)
    }

    func testSecurityConfigurationKeys() {
        // SUFeedURL must be an HTTPS URL
        guard let feedURLString = updateManager.feedURLString else {
            XCTFail("SUFeedURL must be configured in Info.plist")
            return
        }
        XCTAssertTrue(feedURLString.hasPrefix("https://"), "SUFeedURL must strictly use HTTPS")

        // SUPublicEDKey must be a valid 256-bit EdDSA public key (32 bytes base64 = 44 characters)
        guard let edKey = updateManager.publicEDKey else {
            XCTFail("SUPublicEDKey must be configured in Info.plist")
            return
        }
        XCTAssertEqual(edKey.count, 44, "SUPublicEDKey must be a standard base64 256-bit Ed25519 key")
        let decoded = Data(base64Encoded: edKey)
        XCTAssertNotNil(decoded, "SUPublicEDKey must be valid base64")
        XCTAssertEqual(decoded?.count, 32, "Decoded EdDSA public key must be 32 bytes")

        XCTAssertTrue(updateManager.isConfigured)
    }

    func testUpdateStateDescriptions() {
        XCTAssertEqual(UpdateState.idle.statusDescription, "Ready to check for updates")
        XCTAssertEqual(UpdateState.checking.statusDescription, "Checking for updates...")
        XCTAssertEqual(UpdateState.updateAvailable(version: "1.1.0").statusDescription, "Update v1.1.0 is available")
        XCTAssertEqual(UpdateState.upToDate.statusDescription, "ShiftKit is up to date")
        XCTAssertEqual(UpdateState.error("Network offline").statusDescription, "Network offline")
    }

    func testDelegateStateTransitions() {
        // Simulate appcast loaded
        updateManager.didFinishLoadingAppcast()
        XCTAssertNotNil(updateManager.lastCheckDate)

        // Simulate update found
        updateManager.didFindValidUpdate(version: "1.0.1")
        XCTAssertEqual(updateManager.state, .updateAvailable(version: "1.0.1"))

        // Simulate up to date
        updateManager.didNotFindUpdate(error: nil)
        XCTAssertEqual(updateManager.state, .upToDate)

        // Simulate network error
        let error = NSError(domain: "ShiftKitTestDomain", code: -1009, userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."])
        updateManager.didNotFindUpdate(error: error)
        if case .error(let message) = updateManager.state {
            XCTAssertTrue(message.contains("Internet connection appears to be offline"))
        } else {
            XCTFail("State should be .error")
        }

        // Simulate reset
        updateManager.resetState()
        XCTAssertEqual(updateManager.state, .idle)
        XCTAssertNil(updateManager.lastError)
    }

    func testPreferencesMutation() {
        let originalChecks = updateManager.automaticallyChecksForUpdates
        updateManager.automaticallyChecksForUpdates = !originalChecks
        XCTAssertEqual(updateManager.automaticallyChecksForUpdates, !originalChecks)
        updateManager.automaticallyChecksForUpdates = originalChecks

        let originalDownloads = updateManager.automaticallyDownloadsUpdates
        updateManager.automaticallyDownloadsUpdates = !originalDownloads
        XCTAssertEqual(updateManager.automaticallyDownloadsUpdates, !originalDownloads)
        updateManager.automaticallyDownloadsUpdates = originalDownloads
    }
}
