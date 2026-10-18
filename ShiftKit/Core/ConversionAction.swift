import Foundation

// MARK: - Action Category
public enum ConversionActionCategory: String, Hashable, Sendable, CaseIterable {
    case convert
    case compress
    case crop
    case trim
    case merge
    case edit
    case utility

    public var title: String {
        switch self {
        case .convert: return "Convert"
        case .compress: return "Compress"
        case .crop: return "Crop"
        case .trim: return "Trim"
        case .merge: return "Merge"
        case .edit: return "Edit"
        case .utility: return "Utility"
        }
    }
}

// MARK: - Radial Conversion Action
public struct ConversionAction: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let systemIcon: String
    public let category: ConversionActionCategory
    public let targetFormat: String?
    public let options: [String: String]

    public init(
        id: String,
        title: String,
        subtitle: String,
        systemIcon: String,
        category: ConversionActionCategory,
        targetFormat: String? = nil,
        options: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemIcon = systemIcon
        self.category = category
        self.targetFormat = targetFormat
        self.options = options
    }

    // Common action presets
    public static let imageToPNG = ConversionAction(
        id: "img_to_png",
        title: "To PNG",
        subtitle: "Lossless with alpha",
        systemIcon: "photo",
        category: .convert,
        targetFormat: "png"
    )

    public static let imageToJPEG = ConversionAction(
        id: "img_to_jpeg",
        title: "To JPEG",
        subtitle: "High compatibility",
        systemIcon: "photo.stack",
        category: .convert,
        targetFormat: "jpg"
    )

    public static let imageToWebP = ConversionAction(
        id: "img_to_webp",
        title: "To WebP",
        subtitle: "Modern web standard",
        systemIcon: "globe",
        category: .convert,
        targetFormat: "webp"
    )

    public static let imageCompress = ConversionAction(
        id: "img_compress",
        title: "Compress",
        subtitle: "Reduce file size 50%",
        systemIcon: "arrow.down.forward.and.arrow.up.backward",
        category: .compress,
        options: ["quality": "0.75"]
    )

    public static let imageCropSquare = ConversionAction(
        id: "img_crop_square",
        title: "Crop 1:1",
        subtitle: "Square aspect ratio",
        systemIcon: "crop",
        category: .crop,
        options: ["aspect": "square"]
    )

    public static let imageStripMetadata = ConversionAction(
        id: "img_strip_exif",
        title: "Clean EXIF",
        subtitle: "Remove location & camera info",
        systemIcon: "eye.slash",
        category: .utility
    )

    // Video actions
    public static let videoToMP4 = ConversionAction(
        id: "vid_to_mp4",
        title: "To MP4",
        subtitle: "H.264 Universal",
        systemIcon: "film",
        category: .convert,
        targetFormat: "mp4"
    )

    public static let videoToGIF = ConversionAction(
        id: "vid_to_gif",
        title: "To GIF",
        subtitle: "Animated snippet",
        systemIcon: "play.rectangle.on.rectangle",
        category: .convert,
        targetFormat: "gif"
    )

    public static let videoExtractAudio = ConversionAction(
        id: "vid_extract_audio",
        title: "To Audio",
        subtitle: "Extract sound track",
        systemIcon: "waveform",
        category: .convert,
        targetFormat: "mp3"
    )

    public static let videoCompress = ConversionAction(
        id: "vid_compress",
        title: "Compress",
        subtitle: "Fast 1080p Web Profile",
        systemIcon: "arrow.down.right.and.arrow.up.left",
        category: .compress
    )

    public static let videoTrim = ConversionAction(
        id: "vid_trim",
        title: "Trim",
        subtitle: "Open quick trim editor",
        systemIcon: "scissors",
        category: .trim
    )

    // Audio actions
    public static let audioToMP3 = ConversionAction(
        id: "audio_to_mp3",
        title: "To MP3",
        subtitle: "Universal 320kbps",
        systemIcon: "waveform",
        category: .convert,
        targetFormat: "mp3"
    )

    public static let audioToM4A = ConversionAction(
        id: "audio_to_m4a",
        title: "To M4A",
        subtitle: "Apple AAC audio",
        systemIcon: "music.note",
        category: .convert,
        targetFormat: "m4a"
    )

    public static let audioCompress = ConversionAction(
        id: "audio_compress",
        title: "Compress",
        subtitle: "Compact voice / podcast",
        systemIcon: "arrow.down.forward.and.arrow.up.backward",
        category: .compress
    )

    // PDF actions
    public static let pdfCompress = ConversionAction(
        id: "pdf_compress",
        title: "Compress",
        subtitle: "Optimize embedded images",
        systemIcon: "arrow.down.forward.and.arrow.up.backward",
        category: .compress
    )

    public static let pdfToImages = ConversionAction(
        id: "pdf_to_images",
        title: "To Images",
        subtitle: "Export pages as PNGs",
        systemIcon: "photo.stack",
        category: .convert,
        targetFormat: "png"
    )

    public static let pdfMerge = ConversionAction(
        id: "pdf_merge",
        title: "Merge",
        subtitle: "Combine with other PDFs",
        systemIcon: "doc.on.doc",
        category: .merge
    )
}
