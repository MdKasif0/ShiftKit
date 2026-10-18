import Foundation
import CoreGraphics

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
    public var audioBitrateKbps: Int?          // e.g. 192, 256, 320 kbps
    public var audioSampleRateHz: Double?      // e.g. 44100.0, 48000.0
    public var audioChannels: Int?             // 1 = mono, 2 = stereo
    
    // Video Properties
    public var videoFrameRate: Double?         // e.g. 30.0, 60.0 fps
    public var videoResolutionPreset: String?  // e.g. "1080p", "720p", "4k"
    
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
        videoFrameRate: Double? = nil,
        videoResolutionPreset: String? = nil,
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
        self.videoFrameRate = videoFrameRate
        self.videoResolutionPreset = videoResolutionPreset
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
        stripMetadata: false
    )

    public static let webOptimized = ConversionOptions(
        quality: 0.80,
        isLosslessPreferred: false,
        maxDimension: 2048,
        preserveAlpha: true,
        audioBitrateKbps: 192,
        stripMetadata: true
    )

    public static let maximumCompression = ConversionOptions(
        quality: 0.55,
        isLosslessPreferred: false,
        maxDimension: 1280,
        preserveAlpha: false,
        audioBitrateKbps: 128,
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
        if let videoResolutionPreset {
            dict["preset"] = videoResolutionPreset
        }
        return dict
    }
}
