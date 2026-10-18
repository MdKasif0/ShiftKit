import Foundation
import UniformTypeIdentifiers

// MARK: - Output Format Specification
public struct OutputFormat: Identifiable, Hashable, Sendable, Codable {
    public let id: String
    public let displayName: String
    public let uti: String
    public let primaryExtension: String
    public let recognizedExtensions: [String]
    public let mimeType: String
    public let category: FileCategory
    public let supportsAlpha: Bool
    public let supportsAnimation: Bool
    public let isContainerLossy: Bool

    public init(
        id: String,
        displayName: String,
        uti: String,
        primaryExtension: String,
        recognizedExtensions: [String],
        mimeType: String,
        category: FileCategory,
        supportsAlpha: Bool = false,
        supportsAnimation: Bool = false,
        isContainerLossy: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.uti = uti
        self.primaryExtension = primaryExtension.lowercased()
        self.recognizedExtensions = recognizedExtensions.map { $0.lowercased() }
        self.mimeType = mimeType
        self.category = category
        self.supportsAlpha = supportsAlpha
        self.supportsAnimation = supportsAnimation
        self.isContainerLossy = isContainerLossy
    }

    // MARK: - Canonical Formats
    public static let png = OutputFormat(
        id: "png",
        displayName: "PNG Image",
        uti: "public.png",
        primaryExtension: "png",
        recognizedExtensions: ["png"],
        mimeType: "image/png",
        category: .image,
        supportsAlpha: true,
        supportsAnimation: false,
        isContainerLossy: false
    )

    public static let jpeg = OutputFormat(
        id: "jpeg",
        displayName: "JPEG Photo",
        uti: "public.jpeg",
        primaryExtension: "jpg",
        recognizedExtensions: ["jpg", "jpeg", "jpe"],
        mimeType: "image/jpeg",
        category: .image,
        supportsAlpha: false,
        supportsAnimation: false,
        isContainerLossy: true
    )

    public static let webp = OutputFormat(
        id: "webp",
        displayName: "WebP Image",
        uti: "org.webmproject.webp",
        primaryExtension: "webp",
        recognizedExtensions: ["webp"],
        mimeType: "image/webp",
        category: .image,
        supportsAlpha: true,
        supportsAnimation: true,
        isContainerLossy: false
    )

    public static let heic = OutputFormat(
        id: "heic",
        displayName: "HEIC Container",
        uti: "public.heic",
        primaryExtension: "heic",
        recognizedExtensions: ["heic", "heif"],
        mimeType: "image/heic",
        category: .image,
        supportsAlpha: true,
        supportsAnimation: false,
        isContainerLossy: true
    )

    public static let tiff = OutputFormat(
        id: "tiff",
        displayName: "TIFF Archival",
        uti: "public.tiff",
        primaryExtension: "tiff",
        recognizedExtensions: ["tiff", "tif"],
        mimeType: "image/tiff",
        category: .image,
        supportsAlpha: true,
        supportsAnimation: false,
        isContainerLossy: false
    )

    public static let gif = OutputFormat(
        id: "gif",
        displayName: "GIF Graphic",
        uti: "com.compuserve.gif",
        primaryExtension: "gif",
        recognizedExtensions: ["gif"],
        mimeType: "image/gif",
        category: .image,
        supportsAlpha: true,
        supportsAnimation: true,
        isContainerLossy: true
    )

    public static let mp4 = OutputFormat(
        id: "mp4",
        displayName: "MP4 Video (H.264)",
        uti: "public.mpeg-4",
        primaryExtension: "mp4",
        recognizedExtensions: ["mp4", "m4v"],
        mimeType: "video/mp4",
        category: .video,
        supportsAlpha: false,
        supportsAnimation: true,
        isContainerLossy: true
    )

    public static let mov = OutputFormat(
        id: "mov",
        displayName: "QuickTime Movie",
        uti: "com.apple.quicktime-movie",
        primaryExtension: "mov",
        recognizedExtensions: ["mov", "qt"],
        mimeType: "video/quicktime",
        category: .video,
        supportsAlpha: true,
        supportsAnimation: true,
        isContainerLossy: false
    )

    public static let webm = OutputFormat(
        id: "webm",
        displayName: "WebM Video",
        uti: "org.webmproject.webm",
        primaryExtension: "webm",
        recognizedExtensions: ["webm"],
        mimeType: "video/webm",
        category: .video,
        supportsAlpha: true,
        supportsAnimation: true,
        isContainerLossy: true
    )

    public static let mp3 = OutputFormat(
        id: "mp3",
        displayName: "MP3 Audio",
        uti: "public.mp3",
        primaryExtension: "mp3",
        recognizedExtensions: ["mp3"],
        mimeType: "audio/mpeg",
        category: .audio,
        supportsAlpha: false,
        supportsAnimation: false,
        isContainerLossy: true
    )

    public static let m4a = OutputFormat(
        id: "m4a",
        displayName: "M4A Audio (AAC)",
        uti: "com.apple.m4a-audio",
        primaryExtension: "m4a",
        recognizedExtensions: ["m4a", "aac"],
        mimeType: "audio/mp4",
        category: .audio,
        supportsAlpha: false,
        supportsAnimation: false,
        isContainerLossy: true
    )

    public static let wav = OutputFormat(
        id: "wav",
        displayName: "WAV Lossless Audio",
        uti: "com.microsoft.waveform-audio",
        primaryExtension: "wav",
        recognizedExtensions: ["wav", "wave"],
        mimeType: "audio/wav",
        category: .audio,
        supportsAlpha: false,
        supportsAnimation: false,
        isContainerLossy: false
    )

    public static let flac = OutputFormat(
        id: "flac",
        displayName: "FLAC Lossless Audio",
        uti: "org.xiph.flac",
        primaryExtension: "flac",
        recognizedExtensions: ["flac"],
        mimeType: "audio/flac",
        category: .audio,
        supportsAlpha: false,
        supportsAnimation: false,
        isContainerLossy: false
    )

    public static let pdf = OutputFormat(
        id: "pdf",
        displayName: "PDF Document",
        uti: "com.adobe.pdf",
        primaryExtension: "pdf",
        recognizedExtensions: ["pdf"],
        mimeType: "application/pdf",
        category: .pdf,
        supportsAlpha: true,
        supportsAnimation: false,
        isContainerLossy: false
    )

    public static let csv = OutputFormat(
        id: "csv",
        displayName: "CSV Table",
        uti: "public.comma-separated-values-text",
        primaryExtension: "csv",
        recognizedExtensions: ["csv"],
        mimeType: "text/csv",
        category: .structuredData,
        supportsAlpha: false,
        supportsAnimation: false,
        isContainerLossy: false
    )

    public static let json = OutputFormat(
        id: "json",
        displayName: "JSON Data",
        uti: "public.json",
        primaryExtension: "json",
        recognizedExtensions: ["json"],
        mimeType: "application/json",
        category: .structuredData,
        supportsAlpha: false,
        supportsAnimation: false,
        isContainerLossy: false
    )

    public static let txt = OutputFormat(
        id: "txt",
        displayName: "Plain Text",
        uti: "public.plain-text",
        primaryExtension: "txt",
        recognizedExtensions: ["txt", "text"],
        mimeType: "text/plain",
        category: .text,
        supportsAlpha: false,
        supportsAnimation: false,
        isContainerLossy: false
    )

    public static let zip = OutputFormat(
        id: "zip",
        displayName: "ZIP Archive",
        uti: "public.zip-archive",
        primaryExtension: "zip",
        recognizedExtensions: ["zip"],
        mimeType: "application/zip",
        category: .archive,
        supportsAlpha: false,
        supportsAnimation: false,
        isContainerLossy: false
    )

    public static let allCanonical: [OutputFormat] = [
        .png, .jpeg, .webp, .heic, .tiff, .gif,
        .mp4, .mov, .webm,
        .mp3, .m4a, .wav, .flac,
        .pdf, .csv, .json, .txt, .zip
    ]

    public static func find(byExtension ext: String) -> OutputFormat? {
        let clean = ext.lowercased().trimmingCharacters(in: .punctuationCharacters)
        return allCanonical.first { $0.recognizedExtensions.contains(clean) }
    }

    public static func find(byUTI utiString: String) -> OutputFormat? {
        allCanonical.first { $0.uti == utiString }
    }
}
