import Foundation

// MARK: - File Type Hierarchy
public enum FileType: Hashable, Sendable, Identifiable {
    case image(ImageSubtype)
    case video(VideoSubtype)
    case audio(AudioSubtype)
    case pdf
    case document(DocumentSubtype)
    case archive
    case unknown(extensionName: String)

    public var id: String {
        switch self {
        case .image(let sub): return "image_\(sub.rawValue)"
        case .video(let sub): return "video_\(sub.rawValue)"
        case .audio(let sub): return "audio_\(sub.rawValue)"
        case .pdf: return "pdf"
        case .document(let sub): return "doc_\(sub.rawValue)"
        case .archive: return "archive"
        case .unknown(let ext): return "unknown_\(ext)"
        }
    }

    public var displayName: String {
        switch self {
        case .image(let sub): return "\(sub.rawValue.uppercased()) Image"
        case .video(let sub): return "\(sub.rawValue.uppercased()) Video"
        case .audio(let sub): return "\(sub.rawValue.uppercased()) Audio"
        case .pdf: return "PDF Document"
        case .document(let sub): return "\(sub.rawValue.uppercased()) Document"
        case .archive: return "Archive"
        case .unknown(let ext): return ext.isEmpty ? "Unknown File" : "\(ext.uppercased()) File"
        }
    }

    public var systemIcon: String {
        switch self {
        case .image: return "photo"
        case .video: return "film"
        case .audio: return "waveform"
        case .pdf: return "doc.richtext"
        case .document: return "doc.text"
        case .archive: return "archivebox"
        case .unknown: return "doc"
        }
    }

    public var isMedia: Bool {
        switch self {
        case .image, .video, .audio: return true
        default: return false
        }
    }
}

// MARK: - Subtypes
public enum ImageSubtype: String, CaseIterable, Hashable, Sendable {
    case png
    case jpeg
    case heic
    case webp
    case tiff
    case gif
    case svg
    case bmp
    case other
}

public enum VideoSubtype: String, CaseIterable, Hashable, Sendable {
    case mp4
    case mov
    case m4v
    case mkv
    case webm
    case avi
    case other
}

public enum AudioSubtype: String, CaseIterable, Hashable, Sendable {
    case mp3
    case m4a
    case wav
    case aac
    case flac
    case aiff
    case ogg
    case opus
    case other
}

public enum DocumentSubtype: String, CaseIterable, Hashable, Sendable {
    case txt
    case markdown
    case rtf
    case docx
    case csv
    case json
    case other
}
