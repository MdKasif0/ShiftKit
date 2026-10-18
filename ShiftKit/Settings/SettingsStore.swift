import Foundation
import Observation

@Observable
public final class SettingsStore: @unchecked Sendable {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let outputDirectory = "com.shiftkit.settings.outputDirectory"
        static let revealInFinder = "com.shiftkit.settings.revealInFinder"
        static let playSound = "com.shiftkit.settings.playSound"
        static let enableShiftDrag = "com.shiftkit.settings.enableShiftDrag"
        static let keepOriginal = "com.shiftkit.settings.keepOriginal"
        static let ffmpegPath = "com.shiftkit.settings.ffmpegPath"
        static let preferredImageFormat = "com.shiftkit.settings.preferredImageFormat"
    }

    public var outputDirectoryPath: String {
        didSet { defaults.set(outputDirectoryPath, forKey: Keys.outputDirectory) }
    }

    public var revealInFinderOnCompletion: Bool {
        didSet { defaults.set(revealInFinderOnCompletion, forKey: Keys.revealInFinder) }
    }

    public var playSoundOnCompletion: Bool {
        didSet { defaults.set(playSoundOnCompletion, forKey: Keys.playSound) }
    }

    public var enableShiftDragGlobalDetection: Bool {
        didSet { defaults.set(enableShiftDragGlobalDetection, forKey: Keys.enableShiftDrag) }
    }

    public var keepOriginalFiles: Bool {
        didSet { defaults.set(keepOriginalFiles, forKey: Keys.keepOriginal) }
    }

    public var ffmpegPathOverride: String {
        didSet { defaults.set(ffmpegPathOverride, forKey: Keys.ffmpegPath) }
    }

    public var preferredImageFormat: String {
        didSet { defaults.set(preferredImageFormat, forKey: Keys.preferredImageFormat) }
    }

    public init() {
        let defaultDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ShiftKit", isDirectory: true).path ?? "~/Downloads/ShiftKit"

        self.outputDirectoryPath = defaults.string(forKey: Keys.outputDirectory) ?? defaultDir
        self.revealInFinderOnCompletion = defaults.object(forKey: Keys.revealInFinder) as? Bool ?? true
        self.playSoundOnCompletion = defaults.bool(forKey: Keys.playSound)
        self.enableShiftDragGlobalDetection = defaults.object(forKey: Keys.enableShiftDrag) as? Bool ?? true
        self.keepOriginalFiles = defaults.object(forKey: Keys.keepOriginal) as? Bool ?? true
        self.ffmpegPathOverride = defaults.string(forKey: Keys.ffmpegPath) ?? ""
        self.preferredImageFormat = defaults.string(forKey: Keys.preferredImageFormat) ?? "webp"
    }
}
