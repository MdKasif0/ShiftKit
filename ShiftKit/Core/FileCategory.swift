import Foundation

// MARK: - File Category
public enum FileCategory: String, Hashable, Sendable, Codable, CaseIterable {
    case image
    case video
    case audio
    case pdf
    case document
    case text
    case structuredData
    case archive
    case unknown

    public var displayName: String {
        switch self {
        case .image: return "Image"
        case .video: return "Video"
        case .audio: return "Audio"
        case .pdf: return "PDF Document"
        case .document: return "Document"
        case .text: return "Plain Text"
        case .structuredData: return "Structured Data"
        case .archive: return "Archive"
        case .unknown: return "Unknown"
        }
    }

    public var defaultIcon: String {
        switch self {
        case .image: return "photo"
        case .video: return "film"
        case .audio: return "waveform"
        case .pdf: return "doc.richtext"
        case .document: return "doc.text"
        case .text: return "doc.plaintext"
        case .structuredData: return "curlybraces"
        case .archive: return "archivebox"
        case .unknown: return "doc"
        }
    }
}
