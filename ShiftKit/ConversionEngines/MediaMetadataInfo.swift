import Foundation

// MARK: - Media Metadata Model
public struct MediaMetadataInfo: Hashable, Sendable {
    public let duration: Double
    public let formatName: String
    public let fileSize: Int64
    public let overallBitrate: Int64?
    
    // Video Stream
    public let videoCodec: String?
    public let videoWidth: Int?
    public let videoHeight: Int?
    public let videoFrameRate: Double?
    public let pixelFormat: String?
    
    // Audio Stream
    public let audioCodec: String?
    public let audioSampleRate: Double?
    public let audioChannels: Int?
    public let audioBitrate: Int64?
    public let channelLayout: String?
    
    // Subtitles
    public let subtitleStreamsCount: Int
    
    // Tags / Metadata
    public let tags: [String: String]
    
    public init(
        duration: Double = 0.0,
        formatName: String = "",
        fileSize: Int64 = 0,
        overallBitrate: Int64? = nil,
        videoCodec: String? = nil,
        videoWidth: Int? = nil,
        videoHeight: Int? = nil,
        videoFrameRate: Double? = nil,
        pixelFormat: String? = nil,
        audioCodec: String? = nil,
        audioSampleRate: Double? = nil,
        audioChannels: Int? = nil,
        audioBitrate: Int64? = nil,
        channelLayout: String? = nil,
        subtitleStreamsCount: Int = 0,
        tags: [String: String] = [:]
    ) {
        self.duration = duration
        self.formatName = formatName
        self.fileSize = fileSize
        self.overallBitrate = overallBitrate
        self.videoCodec = videoCodec
        self.videoWidth = videoWidth
        self.videoHeight = videoHeight
        self.videoFrameRate = videoFrameRate
        self.pixelFormat = pixelFormat
        self.audioCodec = audioCodec
        self.audioSampleRate = audioSampleRate
        self.audioChannels = audioChannels
        self.audioBitrate = audioBitrate
        self.channelLayout = channelLayout
        self.subtitleStreamsCount = subtitleStreamsCount
        self.tags = tags
    }

    public var title: String? { tags["title"] ?? tags["TITLE"] }
    public var artist: String? { tags["artist"] ?? tags["ARTIST"] ?? tags["author"] }
    public var album: String? { tags["album"] ?? tags["ALBUM"] }
    public var genre: String? { tags["genre"] ?? tags["GENRE"] }
    public var date: String? { tags["date"] ?? tags["DATE"] ?? tags["year"] ?? tags["YEAR"] }
    public var track: String? { tags["track"] ?? tags["TRACK"] }
}
