import Foundation
import CoreGraphics

// MARK: - Video Compression Presets
public enum VideoCompressionPreset: String, CaseIterable, Hashable, Sendable, Codable {
    case smallerFile
    case balanced
    case highQuality
    case custom

    public var displayName: String {
        switch self {
        case .smallerFile: return "Smaller File"
        case .balanced: return "Balanced"
        case .highQuality: return "High Quality"
        case .custom: return "Custom"
        }
    }

    public var subtitle: String {
        switch self {
        case .smallerFile: return "Max compression (720p/1080p, CRF 28)"
        case .balanced: return "Optimal quality vs size (CRF 22)"
        case .highQuality: return "Near-lossless visual fidelity (CRF 18)"
        case .custom: return "Custom bitrate, scale, and fps"
        }
    }
}

// MARK: - Subtitle Handling Action
public enum SubtitleHandlingAction: String, CaseIterable, Hashable, Sendable, Codable {
    case copy
    case strip
}

// MARK: - Conversion Options
/// Configurable options passed to conversion engines to control compression, dimensions, quality, and fidelity.
public struct ConversionOptions: Hashable, Sendable, Codable {
    // Quality & Compression
    public var quality: Double?                // 0.0 ... 1.0 (e.g. 0.85 for lossy formats)
    public var isLosslessPreferred: Bool       // When format supports both (e.g. WebP)
    
    // Geometry & Scaling
    public var maxDimension: Int?              // Maximum width or height constraint
    public var targetWidth: Int?               // Explicit target width
    public var targetHeight: Int?              // Explicit target height
    public var scaleMultiplier: Double?        // Scale factor (e.g. 0.5 for 50%, 2.0 for 2x)
    
    // Transparency & Color
    public var preserveAlpha: Bool             // Maintain alpha channel if target supports it
    public var matteColorHex: String?          // Hex fallback (e.g. "#FFFFFF") when stripping alpha
    
    // Audio Properties
    public var audioBitrateKbps: Int?          // e.g. 128, 192, 256, 320 kbps
    public var audioSampleRateHz: Double?      // e.g. 44100.0, 48000.0
    public var audioChannels: Int?             // 1 = mono, 2 = stereo, 6 = 5.1
    public var volumeMultiplier: Double?       // 1.0 = normal, 1.5 = +50%, 0.5 = -50%
    public var audioTags: [String: String]?    // title, artist, album, genre, date, track, etc.
    
    // Video Properties
    public var videoFrameRate: Double?         // e.g. 24.0, 30.0, 60.0 fps
    public var videoResolutionPreset: String?  // e.g. "1080p", "720p", "4k"
    public var videoCompressionPreset: VideoCompressionPreset?
    public var videoCRF: Int?                  // e.g. 18, 22, 28
    public var videoBitrateKbps: Int?          // e.g. 2500, 5000 kbps
    public var subtitleAction: SubtitleHandlingAction?
    
    // Trimming & Clipping
    public var trimStartTime: Double?          // Start time in seconds
    public var trimEndTime: Double?            // End time in seconds
    
    // Concatenation
    public var concatSourceURLs: [URL]?        // Additional files to join
    
    // Metadata & Structure
    public var stripMetadata: Bool             // Strip EXIF, GPS, camera metadata
    public var pageIndices: [Int]?             // Page numbers to extract or render (0-indexed)
    
    // Custom Engine-Specific Parameters
    public var customParameters: [String: String]

    public init(
        quality: Double? = nil,
        isLosslessPreferred: Bool = false,
        maxDimension: Int? = nil,
        targetWidth: Int? = nil,
        targetHeight: Int? = nil,
        scaleMultiplier: Double? = nil,
        preserveAlpha: Bool = true,
        matteColorHex: String? = nil,
        audioBitrateKbps: Int? = nil,
        audioSampleRateHz: Double? = nil,
        audioChannels: Int? = nil,
        volumeMultiplier: Double? = nil,
        audioTags: [String: String]? = nil,
        videoFrameRate: Double? = nil,
        videoResolutionPreset: String? = nil,
        videoCompressionPreset: VideoCompressionPreset? = nil,
        videoCRF: Int? = nil,
        videoBitrateKbps: Int? = nil,
        subtitleAction: SubtitleHandlingAction? = nil,
        trimStartTime: Double? = nil,
        trimEndTime: Double? = nil,
        concatSourceURLs: [URL]? = nil,
        stripMetadata: Bool = false,
        pageIndices: [Int]? = nil,
        customParameters: [String: String] = [:]
    ) {
        self.quality = quality
        self.isLosslessPreferred = isLosslessPreferred
        self.maxDimension = maxDimension
        self.targetWidth = targetWidth
        self.targetHeight = targetHeight
        self.scaleMultiplier = scaleMultiplier
        self.preserveAlpha = preserveAlpha
        self.matteColorHex = matteColorHex
        self.audioBitrateKbps = audioBitrateKbps
        self.audioSampleRateHz = audioSampleRateHz
        self.audioChannels = audioChannels
        self.volumeMultiplier = volumeMultiplier
        self.audioTags = audioTags
        self.videoFrameRate = videoFrameRate
        self.videoResolutionPreset = videoResolutionPreset
        self.videoCompressionPreset = videoCompressionPreset
        self.videoCRF = videoCRF
        self.videoBitrateKbps = videoBitrateKbps
        self.subtitleAction = subtitleAction
        self.trimStartTime = trimStartTime
        self.trimEndTime = trimEndTime
        self.concatSourceURLs = concatSourceURLs
        self.stripMetadata = stripMetadata
        self.pageIndices = pageIndices
        self.customParameters = customParameters
    }

    // MARK: - Standard Presets
    public static let `default` = ConversionOptions()

    public static let highQuality = ConversionOptions(
        quality: 0.92,
        isLosslessPreferred: true,
        preserveAlpha: true,
        audioBitrateKbps: 320,
        videoCompressionPreset: .highQuality,
        videoCRF: 18,
        stripMetadata: false
    )

    public static let webOptimized = ConversionOptions(
        quality: 0.80,
        isLosslessPreferred: false,
        maxDimension: 2048,
        preserveAlpha: true,
        audioBitrateKbps: 192,
        videoCompressionPreset: .balanced,
        videoCRF: 22,
        stripMetadata: true
    )

    public static let maximumCompression = ConversionOptions(
        quality: 0.55,
        isLosslessPreferred: false,
        maxDimension: 1280,
        preserveAlpha: false,
        audioBitrateKbps: 128,
        videoCompressionPreset: .smallerFile,
        videoCRF: 28,
        stripMetadata: true
    )

    public static let metadataStripped = ConversionOptions(
        stripMetadata: true
    )

    // MARK: - Fluent Helpers
    public func withQuality(_ newQuality: Double) -> ConversionOptions {
        var copy = self
        copy.quality = newQuality
        return copy
    }

    public func withMaxDimension(_ dimension: Int) -> ConversionOptions {
        var copy = self
        copy.maxDimension = dimension
        return copy
    }

    public func strippingMetadata(_ strip: Bool = true) -> ConversionOptions {
        var copy = self
        copy.stripMetadata = strip
        return copy
    }

    public func withTrim(start: Double, end: Double) -> ConversionOptions {
        var copy = self
        copy.trimStartTime = start
        copy.trimEndTime = end
        return copy
    }

    public func withVolume(_ volume: Double) -> ConversionOptions {
        var copy = self
        copy.volumeMultiplier = volume
        return copy
    }

    public func withAudioTags(_ tags: [String: String]) -> ConversionOptions {
        var copy = self
        copy.audioTags = tags
        return copy
    }

    public func withVideoCompression(_ preset: VideoCompressionPreset) -> ConversionOptions {
        var copy = self
        copy.videoCompressionPreset = preset
        switch preset {
        case .smallerFile:
            copy.videoCRF = 28
            copy.audioBitrateKbps = 96
        case .balanced:
            copy.videoCRF = 22
            copy.audioBitrateKbps = 160
        case .highQuality:
            copy.videoCRF = 18
            copy.audioBitrateKbps = 256
        case .custom:
            break
        }
        return copy
    }

    /// Converts options to dictionary representation for legacy or engine compatibility
    public var stringDictionary: [String: String] {
        var dict = customParameters
        if let quality {
            dict["quality"] = String(format: "%.2f", quality)
        }
        if isLosslessPreferred {
            dict["lossless"] = "true"
        }
        if let maxDimension {
            dict["maxDimension"] = "\(maxDimension)"
        }
        if let targetWidth {
            dict["width"] = "\(targetWidth)"
        }
        if let targetHeight {
            dict["height"] = "\(targetHeight)"
        }
        if stripMetadata {
            dict["strip_exif"] = "true"
            dict["strip_metadata"] = "true"
        }
        if let audioBitrateKbps {
            dict["audioBitrate"] = "\(audioBitrateKbps)k"
        }
        if let audioSampleRateHz {
            dict["audioSampleRate"] = "\(Int(audioSampleRateHz))"
        }
        if let audioChannels {
            dict["audioChannels"] = "\(audioChannels)"
        }
        if let volumeMultiplier {
            dict["volume"] = String(format: "%.2f", volumeMultiplier)
        }
        if let videoResolutionPreset {
            dict["preset"] = videoResolutionPreset
        }
        if let videoCompressionPreset {
            dict["compressionPreset"] = videoCompressionPreset.rawValue
        }
        if let videoCRF {
            dict["crf"] = "\(videoCRF)"
        }
        if let trimStartTime {
            dict["trimStart"] = String(format: "%.3f", trimStartTime)
        }
        if let trimEndTime {
            dict["trimEnd"] = String(format: "%.3f", trimEndTime)
        }
        if let subtitleAction {
            dict["subtitles"] = subtitleAction.rawValue
        }
        return dict
    }
}
