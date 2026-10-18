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
    public let pixelWidth: Int?
    public let pixelHeight: Int?
    public let durationSeconds: Double?
    public let pageCount: Int?
    public let createdDate: Date?
    public let modifiedDate: Date?

    public init(
        fileSize: Int64,
        fileExtension: String,
        uti: String? = nil,
        pixelWidth: Int? = nil,
        pixelHeight: Int? = nil,
        durationSeconds: Double? = nil,
        pageCount: Int? = nil,
        createdDate: Date? = nil,
        modifiedDate: Date? = nil
    ) {
        self.fileSize = fileSize
        self.fileExtension = fileExtension.lowercased()
        self.uti = uti
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.durationSeconds = durationSeconds
        self.pageCount = pageCount
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
