import XCTest
@testable import ShiftKit

final class SettingsPersistenceTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!

    override func setUp() {
        super.setUp()
        suiteName = "com.shiftkit.test.settings.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
        settings = SettingsStore(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - Section 1: General Settings Defaults & Mutation

    func testGeneralSettingsDefaultsAndMutation() {
        XCTAssertTrue(settings.showInMenuBar)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertTrue(settings.dockIconVisible)
        XCTAssertEqual(settings.appVersion, "1.0.0")

        settings.showInMenuBar = false
        settings.launchAtLogin = true
        settings.dockIconVisible = false

        let reloaded = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(reloaded.showInMenuBar)
        XCTAssertTrue(reloaded.launchAtLogin)
        XCTAssertFalse(reloaded.dockIconVisible)
    }

    // MARK: - Section 2: Interaction Settings Defaults & Mutation

    func testInteractionSettingsDefaultsAndMutation() {
        XCTAssertTrue(settings.enableShiftDragGlobalDetection)
        XCTAssertEqual(settings.radialAnimation, .spring)
        XCTAssertTrue(settings.keyboardNavigationEnabled)
        XCTAssertEqual(settings.keyboardShortcutDisplay, "⌥⇧S")

        settings.enableShiftDragGlobalDetection = false
        settings.radialAnimation = .reduced
        settings.keyboardNavigationEnabled = false

        let reloaded = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(reloaded.enableShiftDragGlobalDetection)
        XCTAssertEqual(reloaded.radialAnimation, .reduced)
        XCTAssertFalse(reloaded.keyboardNavigationEnabled)
    }

    // MARK: - Section 3: Conversion Settings Defaults & Mutation

    func testConversionSettingsDefaultsAndMutation() {
        XCTAssertEqual(settings.maxConcurrentJobs, 2)
        XCTAssertEqual(settings.defaultImageQuality, 0.85)
        XCTAssertEqual(settings.defaultVideoPreset, "balanced")
        XCTAssertEqual(settings.defaultAudioBitrateKbps, 192)

        settings.maxConcurrentJobs = 5
        settings.defaultImageQuality = 0.95
        settings.defaultVideoPreset = "fast"
        settings.defaultAudioBitrateKbps = 320

        let reloaded = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(reloaded.maxConcurrentJobs, 5)
        XCTAssertEqual(reloaded.defaultImageQuality, 0.95)
        XCTAssertEqual(reloaded.defaultVideoPreset, "fast")
        XCTAssertEqual(reloaded.defaultAudioBitrateKbps, 320)
    }

    // MARK: - Section 4: Output Settings Defaults & Mutation

    func testOutputSettingsDefaultsAndMutation() {
        XCTAssertEqual(settings.outputLocationPreference, .dedicatedFolder)
        XCTAssertEqual(settings.filenameConflictResolution, .renameWithNumber)
        XCTAssertTrue(settings.revealInFinderOnCompletion)

        let customDir = "/tmp/custom_shiftkit_output"
        settings.outputLocationPreference = .besideOriginal
        settings.filenameConflictResolution = .failWithConflict
        settings.revealInFinderOnCompletion = false
        settings.outputDirectoryPath = customDir

        let reloaded = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(reloaded.outputLocationPreference, .besideOriginal)
        XCTAssertEqual(reloaded.filenameConflictResolution, .failWithConflict)
        XCTAssertFalse(reloaded.revealInFinderOnCompletion)
        XCTAssertEqual(reloaded.outputDirectoryPath, customDir)
    }

    // MARK: - Section 5: Temporary Files Cleanup

    func testTemporaryFilesCleanup() {
        let freed = settings.cleanTemporaryFiles()
        XCTAssertGreaterThanOrEqual(freed, 0)
    }

    // MARK: - Reset To Defaults

    func testResetToDefaults() {
        // Mutate everything
        settings.showInMenuBar = false
        settings.maxConcurrentJobs = 8
        settings.enableShiftDragGlobalDetection = false
        settings.filenameConflictResolution = .overwrite
        settings.revealInFinderOnCompletion = false

        // Reset
        settings.resetToDefaults()

        XCTAssertTrue(settings.showInMenuBar)
        XCTAssertEqual(settings.maxConcurrentJobs, 2)
        XCTAssertTrue(settings.enableShiftDragGlobalDetection)
        XCTAssertEqual(settings.filenameConflictResolution, .renameWithNumber)
        XCTAssertTrue(settings.revealInFinderOnCompletion)
    }
}
