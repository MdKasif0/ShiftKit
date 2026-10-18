import Foundation
import Observation

// MARK: - Settings Enums
public enum OutputLocationPreference: String, CaseIterable, Identifiable, Sendable {
    case besideOriginal = "besideOriginal"
    case dedicatedFolder = "dedicatedFolder"
    case askEveryTime = "askEveryTime"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .besideOriginal: return "Save Beside Original"
        case .dedicatedFolder: return "Dedicated Folder"
        case .askEveryTime: return "Ask Every Time"
        }
    }
}

public enum FilenameConflictResolution: String, CaseIterable, Identifiable, Sendable {
    case renameWithNumber = "rename"
    case overwrite = "overwrite"
    case failWithConflict = "fail"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .renameWithNumber: return "Keep Both (Auto-number)"
        case .overwrite: return "Overwrite Existing File"
        case .failWithConflict: return "Stop and Report Conflict"
        }
    }
}

public enum RadialMenuAnimationStyle: String, CaseIterable, Identifiable, Sendable {
    case spring = "spring"
    case smooth = "smooth"
    case snappy = "snappy"
    case reduced = "reduced"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .spring: return "Spring (Elastic & Lively)"
        case .smooth: return "Smooth (Gentle Ease)"
        case .snappy: return "Snappy (Fast & Responsive)"
        case .reduced: return "Reduced Motion (Fade Only)"
        }
    }
}

@Observable
public final class SettingsStore: @unchecked Sendable {
    public static let shared = SettingsStore()

    private let defaults: UserDefaults

    public enum Keys {
        public static let outputDirectory = "com.shiftkit.settings.outputDirectory"
        public static let outputPreference = "com.shiftkit.settings.outputPreference"
        public static let conflictResolution = "com.shiftkit.settings.conflictResolution"
        public static let revealInFinder = "com.shiftkit.settings.revealInFinder"
        public static let playSound = "com.shiftkit.settings.playSound"
        public static let enableShiftDrag = "com.shiftkit.settings.enableShiftDrag"
        public static let keepOriginal = "com.shiftkit.settings.keepOriginal"
        public static let ffmpegPath = "com.shiftkit.settings.ffmpegPath"
        public static let preferredImageFormat = "com.shiftkit.settings.preferredImageFormat"
        public static let showInMenuBar = "com.shiftkit.settings.showInMenuBar"
        public static let dockIconVisible = "com.shiftkit.settings.dockIconVisible"
        public static let launchAtLogin = "com.shiftkit.settings.launchAtLogin"
        public static let maxConcurrentJobs = "com.shiftkit.settings.maxConcurrentJobs"
        public static let radialAnimation = "com.shiftkit.settings.radialAnimation"
        public static let keyboardNav = "com.shiftkit.settings.keyboardNav"
        public static let imageQuality = "com.shiftkit.settings.imageQuality"
        public static let audioBitrate = "com.shiftkit.settings.audioBitrate"
        public static let videoPreset = "com.shiftkit.settings.videoPreset"
    }

    // MARK: - General
    public var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            LaunchAtLoginManager.shared.setEnabled(launchAtLogin)
        }
    }

    public var showInMenuBar: Bool {
        didSet { defaults.set(showInMenuBar, forKey: Keys.showInMenuBar) }
    }

    public var dockIconVisible: Bool {
        didSet { defaults.set(dockIconVisible, forKey: Keys.dockIconVisible) }
    }

    public var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    public var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Interaction
    public var enableShiftDragGlobalDetection: Bool {
        didSet { defaults.set(enableShiftDragGlobalDetection, forKey: Keys.enableShiftDrag) }
    }

    public var radialAnimation: RadialMenuAnimationStyle {
        didSet { defaults.set(radialAnimation.rawValue, forKey: Keys.radialAnimation) }
    }

    public var keyboardNavigationEnabled: Bool {
        didSet { defaults.set(keyboardNavigationEnabled, forKey: Keys.keyboardNav) }
    }

    public var keyboardShortcutDisplay: String {
        "⌥⇧S"
    }

    // MARK: - Conversion Defaults
    public var maxConcurrentJobs: Int {
        didSet {
            defaults.set(maxConcurrentJobs, forKey: Keys.maxConcurrentJobs)
            JobManager.shared.updateMaxConcurrency(maxConcurrentJobs)
        }
    }

    public var defaultImageQuality: Double {
        didSet { defaults.set(defaultImageQuality, forKey: Keys.imageQuality) }
    }

    public var defaultAudioBitrateKbps: Int {
        didSet { defaults.set(defaultAudioBitrateKbps, forKey: Keys.audioBitrate) }
    }

    public var defaultVideoPreset: String {
        didSet { defaults.set(defaultVideoPreset, forKey: Keys.videoPreset) }
    }

    public var preferredImageFormat: String {
        didSet { defaults.set(preferredImageFormat, forKey: Keys.preferredImageFormat) }
    }

    public var ffmpegPathOverride: String {
        didSet { defaults.set(ffmpegPathOverride, forKey: Keys.ffmpegPath) }
    }

    // MARK: - Output & Filesystem
    public var outputLocationPreference: OutputLocationPreference {
        didSet { defaults.set(outputLocationPreference.rawValue, forKey: Keys.outputPreference) }
    }

    public var outputDirectoryPath: String {
        didSet { defaults.set(outputDirectoryPath, forKey: Keys.outputDirectory) }
    }

    public var filenameConflictResolution: FilenameConflictResolution {
        didSet { defaults.set(filenameConflictResolution.rawValue, forKey: Keys.conflictResolution) }
    }

    public var revealInFinderOnCompletion: Bool {
        didSet { defaults.set(revealInFinderOnCompletion, forKey: Keys.revealInFinder) }
    }

    public var playSoundOnCompletion: Bool {
        didSet { defaults.set(playSoundOnCompletion, forKey: Keys.playSound) }
    }

    public var keepOriginalFiles: Bool {
        didSet { defaults.set(keepOriginalFiles, forKey: Keys.keepOriginal) }
    }

    // MARK: - Lifecycle
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let defaultDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ShiftKit", isDirectory: true).path ?? "~/Downloads/ShiftKit"

        self.outputDirectoryPath = defaults.string(forKey: Keys.outputDirectory) ?? defaultDir

        let rawPref = defaults.string(forKey: Keys.outputPreference) ?? OutputLocationPreference.dedicatedFolder.rawValue
        self.outputLocationPreference = OutputLocationPreference(rawValue: rawPref) ?? .dedicatedFolder

        let rawConflict = defaults.string(forKey: Keys.conflictResolution) ?? FilenameConflictResolution.renameWithNumber.rawValue
        self.filenameConflictResolution = FilenameConflictResolution(rawValue: rawConflict) ?? .renameWithNumber

        self.revealInFinderOnCompletion = defaults.object(forKey: Keys.revealInFinder) as? Bool ?? true
        self.playSoundOnCompletion = defaults.bool(forKey: Keys.playSound)
        self.enableShiftDragGlobalDetection = defaults.object(forKey: Keys.enableShiftDrag) as? Bool ?? true
        self.keepOriginalFiles = defaults.object(forKey: Keys.keepOriginal) as? Bool ?? true
        self.ffmpegPathOverride = defaults.string(forKey: Keys.ffmpegPath) ?? ""
        self.preferredImageFormat = defaults.string(forKey: Keys.preferredImageFormat) ?? "webp"
        self.showInMenuBar = defaults.object(forKey: Keys.showInMenuBar) as? Bool ?? true
        self.dockIconVisible = defaults.object(forKey: Keys.dockIconVisible) as? Bool ?? true
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.maxConcurrentJobs = defaults.object(forKey: Keys.maxConcurrentJobs) as? Int ?? 2

        let rawAnim = defaults.string(forKey: Keys.radialAnimation) ?? RadialMenuAnimationStyle.spring.rawValue
        self.radialAnimation = RadialMenuAnimationStyle(rawValue: rawAnim) ?? .spring

        self.keyboardNavigationEnabled = defaults.object(forKey: Keys.keyboardNav) as? Bool ?? true
        self.defaultImageQuality = defaults.object(forKey: Keys.imageQuality) as? Double ?? 0.85
        self.defaultAudioBitrateKbps = defaults.object(forKey: Keys.audioBitrate) as? Int ?? 192
        self.defaultVideoPreset = defaults.string(forKey: Keys.videoPreset) ?? "balanced"
    }

    public func resetToDefaults() {
        let defaultDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ShiftKit", isDirectory: true).path ?? "~/Downloads/ShiftKit"

        outputDirectoryPath = defaultDir
        outputLocationPreference = .dedicatedFolder
        filenameConflictResolution = .renameWithNumber
        revealInFinderOnCompletion = true
        playSoundOnCompletion = false
        enableShiftDragGlobalDetection = true
        keepOriginalFiles = true
        ffmpegPathOverride = ""
        preferredImageFormat = "webp"
        showInMenuBar = true
        dockIconVisible = true
        launchAtLogin = false
        maxConcurrentJobs = 2
        radialAnimation = .spring
        keyboardNavigationEnabled = true
        defaultImageQuality = 0.85
        defaultAudioBitrateKbps = 192
        defaultVideoPreset = "balanced"
    }

    /// Cleans orphaned temporary conversion files created in the app working folders
    @discardableResult
    public func cleanTemporaryFiles() -> Int64 {
        let fm = FileManager.default
        var bytesFreed: Int64 = 0

        let tempDirs = [
            fm.temporaryDirectory,
            URL(fileURLWithPath: outputDirectoryPath)
        ]

        for dir in tempDirs {
            guard let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey]) else { continue }
            for file in contents {
                let name = file.lastPathComponent
                if name.hasPrefix(".tmp_") || name.contains(".tmp-") {
                    if let size = (try? fm.attributesOfItem(atPath: file.path)[.size] as? NSNumber)?.int64Value {
                        bytesFreed += size
                    }
                    try? fm.removeItem(at: file)
                }
            }
        }
        return bytesFreed
    }
}
