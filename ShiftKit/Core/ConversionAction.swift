import Foundation

// MARK: - Action Category
public enum ConversionActionCategory: String, Hashable, Sendable, CaseIterable, Codable {
    case convert
    case compress
    case cropOrTrim
    case merge
    case edit
    case metadata
    case extract
    case more

    public var title: String {
        switch self {
        case .convert: return "Convert"
        case .compress: return "Compress"
        case .cropOrTrim: return "Crop / Trim"
        case .merge: return "Merge"
        case .edit: return "Edit"
        case .metadata: return "Metadata"
        case .extract: return "Extract"
        case .more: return "More"
        }
    }

    public var defaultIcon: String {
        switch self {
        case .convert: return "arrow.triangle.2.circlepath"
        case .compress: return "arrow.down.forward.and.arrow.up.backward"
        case .cropOrTrim: return "crop"
        case .merge: return "doc.on.doc"
        case .edit: return "slider.horizontal.3"
        case .metadata: return "info.circle"
        case .extract: return "arrow.up.right.and.arrow.down.left.rectangle"
        case .more: return "ellipsis.circle"
        }
    }
}

public typealias ActionCategory = ConversionActionCategory

// MARK: - Radial Conversion Action
public struct ConversionAction: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let systemIcon: String
    public let category: ConversionActionCategory
    public let targetFormat: String?
    public let badgeTag: String?
    public let options: [String: String]

    public init(
        id: String,
        title: String,
        subtitle: String,
        systemIcon: String,
        category: ConversionActionCategory,
        targetFormat: String? = nil,
        badgeTag: String? = nil,
        options: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemIcon = systemIcon
        self.category = category
        self.targetFormat = targetFormat
        self.badgeTag = badgeTag
        self.options = options
    }

    // Common standard presets
    public static let imageToPNG = ConversionAction(
        id: "img_to_png",
        title: "To PNG",
        subtitle: "Lossless with alpha channel",
        systemIcon: "photo",
        category: .convert,
        targetFormat: "png",
        badgeTag: "Lossless"
    )

    public static let imageToJPEG = ConversionAction(
        id: "img_to_jpeg",
        title: "To JPEG",
        subtitle: "Universal photo standard",
        systemIcon: "photo.stack",
        category: .convert,
        targetFormat: "jpg",
        badgeTag: "Universal"
    )

    public static let imageToWebP = ConversionAction(
        id: "img_to_webp",
        title: "To WebP",
        subtitle: "Modern high-efficiency web image",
        systemIcon: "globe",
        category: .convert,
        targetFormat: "webp",
        badgeTag: "Web Standard"
    )

    public static let imageToHEIC = ConversionAction(
        id: "img_to_heic",
        title: "To HEIC",
        subtitle: "Apple High Efficiency container",
        systemIcon: "apple.logo",
        category: .convert,
        targetFormat: "heic",
        badgeTag: "Compact"
    )

    public static let imageToTIFF = ConversionAction(
        id: "img_to_tiff",
        title: "To TIFF",
        subtitle: "Uncompressed print / archival",
        systemIcon: "printer",
        category: .convert,
        targetFormat: "tiff",
        badgeTag: "Archival"
    )

    public static let imageCompress = ConversionAction(
        id: "img_compress",
        title: "Balanced Compression",
        subtitle: "Reduce file size ~40-60%",
        systemIcon: "arrow.down.forward.and.arrow.up.backward",
        category: .compress,
        badgeTag: "Recommended",
        options: ["quality": "0.75"]
    )

    public static let imageCropSquare = ConversionAction(
        id: "img_crop_square",
        title: "Crop 1:1 Square",
        subtitle: "Center square aspect ratio",
        systemIcon: "crop",
        category: .cropOrTrim,
        badgeTag: "Square",
        options: ["aspect": "square"]
    )

    public static let imageStripMetadata = ConversionAction(
        id: "img_strip_exif",
        title: "Clean EXIF / GPS",
        subtitle: "Remove location, serial & camera info",
        systemIcon: "eye.slash",
        category: .metadata,
        badgeTag: "Privacy"
    )

    // Video actions
    public static let videoToMP4 = ConversionAction(
        id: "vid_to_mp4",
        title: "To MP4",
        subtitle: "H.264 Universal Compatibility",
        systemIcon: "film",
        category: .convert,
        targetFormat: "mp4",
        badgeTag: "H.264"
    )

    public static let videoToGIF = ConversionAction(
        id: "vid_to_gif",
        title: "To Animated GIF",
        subtitle: "Palette-optimized loop snippet",
        systemIcon: "play.rectangle.on.rectangle",
        category: .convert,
        targetFormat: "gif",
        badgeTag: "GIF"
    )

    public static let videoExtractAudio = ConversionAction(
        id: "vid_extract_audio",
        title: "Extract MP3 Audio",
        subtitle: "Extract sound track to MP3",
        systemIcon: "waveform",
        category: .extract,
        targetFormat: "mp3",
        badgeTag: "MP3"
    )

    public static let videoCompress = ConversionAction(
        id: "vid_compress",
        title: "Compress 1080p",
        subtitle: "Fast 1080p Web Profile",
        systemIcon: "arrow.down.right.and.arrow.up.left",
        category: .compress,
        badgeTag: "1080p"
    )

    public static let videoTrim = ConversionAction(
        id: "vid_trim",
        title: "Trim Video",
        subtitle: "Trim start / end duration",
        systemIcon: "scissors",
        category: .cropOrTrim,
        badgeTag: "Trim"
    )

    // Additional Video Actions
    public static let videoToWebM = ConversionAction(
        id: "vid_to_webm",
        title: "To WebM",
        subtitle: "VP9 Modern Web Standard",
        systemIcon: "globe",
        category: .convert,
        targetFormat: "webm",
        badgeTag: "VP9"
    )

    public static let videoToMKV = ConversionAction(
        id: "vid_to_mkv",
        title: "To MKV",
        subtitle: "Matroska Multimedia Container",
        systemIcon: "film.stack",
        category: .convert,
        targetFormat: "mkv",
        badgeTag: "MKV"
    )

    // Audio actions
    public static let audioToMP3 = ConversionAction(
        id: "audio_to_mp3",
        title: "To MP3",
        subtitle: "Universal 320kbps CBR",
        systemIcon: "waveform",
        category: .convert,
        targetFormat: "mp3",
        badgeTag: "320k"
    )

    public static let audioToM4A = ConversionAction(
        id: "audio_to_m4a",
        title: "To M4A (AAC)",
        subtitle: "Apple AAC high fidelity",
        systemIcon: "music.note",
        category: .convert,
        targetFormat: "m4a",
        badgeTag: "AAC"
    )

    public static let audioCompress = ConversionAction(
        id: "audio_compress",
        title: "Compress Audio",
        subtitle: "Speech & podcast optimized",
        systemIcon: "arrow.down.forward.and.arrow.up.backward",
        category: .compress,
        badgeTag: "Voice"
    )

    public static let audioToWAV = ConversionAction(
        id: "audio_to_wav",
        title: "To WAV",
        subtitle: "Uncompressed PCM audio",
        systemIcon: "waveform",
        category: .convert,
        targetFormat: "wav",
        badgeTag: "PCM"
    )

    public static let audioToFLAC = ConversionAction(
        id: "audio_to_flac",
        title: "To FLAC",
        subtitle: "Free Lossless Audio Codec",
        systemIcon: "waveform.path.ecg",
        category: .convert,
        targetFormat: "flac",
        badgeTag: "Lossless"
    )

    public static let audioToAAC = ConversionAction(
        id: "audio_to_aac",
        title: "To AAC",
        subtitle: "Advanced Audio Coding",
        systemIcon: "music.note",
        category: .convert,
        targetFormat: "aac",
        badgeTag: "AAC"
    )

    public static let audioToOGG = ConversionAction(
        id: "audio_to_ogg",
        title: "To OGG (Vorbis)",
        subtitle: "Open media standard",
        systemIcon: "speaker.wave.2",
        category: .convert,
        targetFormat: "ogg",
        badgeTag: "OGG"
    )

    public static let audioToOpus = ConversionAction(
        id: "audio_to_opus",
        title: "To Opus",
        subtitle: "Low latency modern codec",
        systemIcon: "waveform.badge.magnifyingglass",
        category: .convert,
        targetFormat: "opus",
        badgeTag: "Opus"
    )

    public static let audioTrim = ConversionAction(
        id: "audio_trim",
        title: "Trim Audio",
        subtitle: "Trim duration with precision",
        systemIcon: "scissors",
        category: .cropOrTrim,
        badgeTag: "Trim"
    )

    // PDF actions
    public static let pdfCompress = ConversionAction(
        id: "pdf_compress",
        title: "Compress PDF",
        subtitle: "Downsample images & clean stream",
        systemIcon: "arrow.down.forward.and.arrow.up.backward",
        category: .compress,
        badgeTag: "Compact"
    )

    public static let pdfToImages = ConversionAction(
        id: "pdf_to_images",
        title: "Pages to PNG",
        subtitle: "Render pages as PNG images",
        systemIcon: "photo.stack",
        category: .convert,
        targetFormat: "png",
        badgeTag: "PNG Pages"
    )

    public static let pdfMerge = ConversionAction(
        id: "pdf_merge",
        title: "Merge PDFs",
        subtitle: "Combine with additional documents",
        systemIcon: "doc.on.doc",
        category: .merge,
        badgeTag: "Merge"
    )

    public static let imageToPDF = ConversionAction(
        id: "img_to_pdf",
        title: "Create PDF",
        subtitle: "Package image(s) into PDF document",
        systemIcon: "doc.richtext",
        category: .convert,
        targetFormat: "pdf",
        badgeTag: "PDF"
    )

    public static let pdfToJPEG = ConversionAction(
        id: "pdf_to_jpeg",
        title: "Pages to JPEG",
        subtitle: "Render pages as compressed JPEG",
        systemIcon: "photo.stack",
        category: .convert,
        targetFormat: "jpeg",
        badgeTag: "JPEG Pages"
    )

    public static let pdfSplit = ConversionAction(
        id: "pdf_split",
        title: "Split Pages",
        subtitle: "Extract each page to separate file",
        systemIcon: "arrow.up.and.down.and.arrow.left.and.right",
        category: .extract,
        targetFormat: "pdf",
        badgeTag: "Split"
    )

    public static let pdfExtractPages = ConversionAction(
        id: "pdf_extract_pages",
        title: "Extract Pages",
        subtitle: "Extract selected page range",
        systemIcon: "doc.badge.arrow.up",
        category: .extract,
        targetFormat: "pdf",
        badgeTag: "Extract"
    )

    public static let pdfRotate = ConversionAction(
        id: "pdf_rotate_90",
        title: "Rotate 90° Clockwise",
        subtitle: "Rotate document orientation",
        systemIcon: "rotate.right",
        category: .edit,
        badgeTag: "Rotate",
        options: ["degrees": "90"]
    )

    public static let pdfExtractText = ConversionAction(
        id: "pdf_extract_text",
        title: "Extract Text",
        subtitle: "Extract text stream to .txt",
        systemIcon: "doc.plaintext",
        category: .extract,
        targetFormat: "txt",
        badgeTag: "Text"
    )

    public static let pdfWatermark = ConversionAction(
        id: "pdf_watermark",
        title: "Add Watermark",
        subtitle: "Stamp diagonal watermark text",
        systemIcon: "text.and.command.macparagraph",
        category: .edit,
        badgeTag: "Watermark"
    )

    public static let pdfStripMetadata = ConversionAction(
        id: "pdf_strip_metadata",
        title: "Clean PDF Metadata",
        subtitle: "Strip author, producer & edit info",
        systemIcon: "eye.slash",
        category: .metadata,
        badgeTag: "Privacy"
    )

    // Document & Developer Actions
    public static let docToPDF = ConversionAction(
        id: "doc_to_pdf",
        title: "To PDF Document",
        subtitle: "Paginate to standard PDF",
        systemIcon: "doc.richtext",
        category: .convert,
        targetFormat: "pdf",
        badgeTag: "PDF"
    )

    public static let docToDOCX = ConversionAction(
        id: "doc_to_docx",
        title: "To Word (.docx)",
        subtitle: "Microsoft Word container",
        systemIcon: "doc.text",
        category: .convert,
        targetFormat: "docx",
        badgeTag: "DOCX"
    )

    public static let docToHTML = ConversionAction(
        id: "doc_to_html",
        title: "To HTML Document",
        subtitle: "Web-ready semantic HTML",
        systemIcon: "globe",
        category: .convert,
        targetFormat: "html",
        badgeTag: "HTML"
    )

    public static let docToRTF = ConversionAction(
        id: "doc_to_rtf",
        title: "To Rich Text (.rtf)",
        subtitle: "Universal formatted rich text",
        systemIcon: "doc.richtext",
        category: .convert,
        targetFormat: "rtf",
        badgeTag: "RTF"
    )

    public static let docToTXT = ConversionAction(
        id: "doc_to_txt",
        title: "To Plain Text (.txt)",
        subtitle: "Strip formatting to text",
        systemIcon: "doc.plaintext",
        category: .convert,
        targetFormat: "txt",
        badgeTag: "TXT"
    )

    public static let csvToJSON = ConversionAction(
        id: "csv_to_json",
        title: "CSV to JSON",
        subtitle: "Parse table to JSON records",
        systemIcon: "curlybraces",
        category: .convert,
        targetFormat: "json",
        badgeTag: "JSON"
    )

    public static let jsonToCSV = ConversionAction(
        id: "json_to_csv",
        title: "JSON to CSV Table",
        subtitle: "Flatten JSON objects to table",
        systemIcon: "tablecells",
        category: .convert,
        targetFormat: "csv",
        badgeTag: "CSV"
    )

    public static let jsonToYAML = ConversionAction(
        id: "json_to_yaml",
        title: "JSON to YAML",
        subtitle: "Convert to YAML document",
        systemIcon: "list.bullet.indent",
        category: .convert,
        targetFormat: "yaml",
        badgeTag: "YAML"
    )

    public static let yamlToJSON = ConversionAction(
        id: "yaml_to_json",
        title: "YAML to JSON",
        subtitle: "Convert to formatted JSON",
        systemIcon: "curlybraces",
        category: .convert,
        targetFormat: "json",
        badgeTag: "JSON"
    )

    public static let jsonFormat = ConversionAction(
        id: "json_format",
        title: "Format & Validate JSON",
        subtitle: "Pretty-print indented syntax",
        systemIcon: "checkmark.seal",
        category: .edit,
        targetFormat: "json",
        badgeTag: "Beautify"
    )

    public static let zipCreate = ConversionAction(
        id: "zip_create",
        title: "Compress to ZIP",
        subtitle: "Standard local ZIP archive",
        systemIcon: "archivebox",
        category: .compress,
        targetFormat: "zip",
        badgeTag: "ZIP"
    )

    public static let zipExtract = ConversionAction(
        id: "zip_extract",
        title: "Extract Archive",
        subtitle: "Safe extraction (Zip Slip protected)",
        systemIcon: "archivebox.arrow.up",
        category: .extract,
        badgeTag: "Extract"
    )

    public static let hashSHA256 = ConversionAction(
        id: "hash_sha256",
        title: "Compute SHA-256",
        subtitle: "Cryptographic integrity hash",
        systemIcon: "number.square",
        category: .metadata,
        badgeTag: "SHA-256"
    )

    public static let base64Encode = ConversionAction(
        id: "base64_encode",
        title: "Base64 Encode",
        subtitle: "Export file as Base64 text",
        systemIcon: "character.textbox",
        category: .convert,
        targetFormat: "txt",
        badgeTag: "Base64"
    )
}

// MARK: - Radial Segment Item (8 Contextual Slices)
public struct RadialSegmentItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let systemIcon: String
    public let shortcutKey: String // "1" ... "8"
    public let category: ConversionActionCategory
    public let isEnabled: Bool
    public let subActions: [ConversionAction]

    public init(
        id: String,
        title: String,
        subtitle: String,
        systemIcon: String,
        shortcutKey: String,
        category: ConversionActionCategory,
        isEnabled: Bool = true,
        subActions: [ConversionAction] = []
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemIcon = systemIcon
        self.shortcutKey = shortcutKey
        self.category = category
        self.isEnabled = isEnabled
        self.subActions = subActions
    }
}
