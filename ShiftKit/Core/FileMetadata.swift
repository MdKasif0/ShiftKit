import Foundation

// MARK: - Inspected File Model
public struct InspectedFile: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let url: URL
    public let fileName: String
    public let fileType: FileType
    public let metadata: FileMetadata

    public init(
        id: UUID = UUID(),
        url: URL,
        fileName: String? = nil,
        fileType: FileType,
        metadata: FileMetadata
    ) {
        self.id = id
        self.url = url
        self.fileName = fileName ?? url.lastPathComponent
        self.fileType = fileType
        self.metadata = metadata
    }
}

// MARK: - Detailed Metadata
public struct FileMetadata: Hashable, Sendable {
    public let fileSize: Int64
    public let fileExtension: String
    public let uti: String?
    public let mimeType: String?
    
    // Image Properties
    public let pixelWidth: Int?
    public let pixelHeight: Int?
    public let colorSpace: String?
    public let hasAlphaChannel: Bool
    
    // Audio Properties
    public let durationSeconds: Double?
    public let audioChannels: Int?
    public let audioSampleRate: Double?
    public let audioBitrate: Int?
    public let audioCodec: String?
    
    // Video Properties
    public let videoFrameRate: Double?
    public let videoCodec: String?
    
    // Document & PDF Properties
    public let pageCount: Int?
    public let isEncrypted: Bool
    public let documentTitle: String?
    public let documentAuthor: String?
    
    // Format Fidelity & Inspection Flags
    public let isFormatExtensionMismatch: Bool
    public let detectedFormat: OutputFormat?
    
    // Timestamps
    public let createdDate: Date?
    public let modifiedDate: Date?

    public init(
        fileSize: Int64,
        fileExtension: String,
        uti: String? = nil,
        mimeType: String? = nil,
        pixelWidth: Int? = nil,
        pixelHeight: Int? = nil,
        colorSpace: String? = nil,
        hasAlphaChannel: Bool = false,
        durationSeconds: Double? = nil,
        audioChannels: Int? = nil,
        audioSampleRate: Double? = nil,
        audioBitrate: Int? = nil,
        audioCodec: String? = nil,
        videoFrameRate: Double? = nil,
        videoCodec: String? = nil,
        pageCount: Int? = nil,
        isEncrypted: Bool = false,
        documentTitle: String? = nil,
        documentAuthor: String? = nil,
        isFormatExtensionMismatch: Bool = false,
        detectedFormat: OutputFormat? = nil,
        createdDate: Date? = nil,
        modifiedDate: Date? = nil
    ) {
        self.fileSize = fileSize
        self.fileExtension = fileExtension.lowercased()
        self.uti = uti
        self.mimeType = mimeType
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.colorSpace = colorSpace
        self.hasAlphaChannel = hasAlphaChannel
        self.durationSeconds = durationSeconds
        self.audioChannels = audioChannels
        self.audioSampleRate = audioSampleRate
        self.audioBitrate = audioBitrate
        self.audioCodec = audioCodec
        self.videoFrameRate = videoFrameRate
        self.videoCodec = videoCodec
        self.pageCount = pageCount
        self.isEncrypted = isEncrypted
        self.documentTitle = documentTitle
        self.documentAuthor = documentAuthor
        self.isFormatExtensionMismatch = isFormatExtensionMismatch
        self.detectedFormat = detectedFormat
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
    }

    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    public var dimensionsDescription: String? {
        guard let w = pixelWidth, let h = pixelHeight else { return nil }
        return "\(w) × \(h) px"
    }

    public var durationDescription: String? {
        guard let duration = durationSeconds, duration > 0 else { return nil }
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}
