import Foundation
import UniformTypeIdentifiers

// MARK: - Protocol
public protocol FileTypeDetecting: Sendable {
    func detectType(for url: URL) -> FileType
}

// MARK: - Implementation
public final class FileTypeDetector: FileTypeDetecting {
    public init() {}

    public func detectType(for url: URL) -> FileType {
        let pathExtension = url.pathExtension.lowercased()

        // 1. Direct extension-based classification first for canonical subtypes
        switch pathExtension {
        // Images
        case "png": return .image(.png)
        case "jpg", "jpeg": return .image(.jpeg)
        case "heic", "heif": return .image(.heic)
        case "webp": return .image(.webp)
        case "tiff", "tif": return .image(.tiff)
        case "gif": return .image(.gif)
        case "svg": return .image(.svg)
        case "bmp": return .image(.bmp)

        // Videos
        case "mp4": return .video(.mp4)
        case "mov": return .video(.mov)
        case "m4v": return .video(.m4v)
        case "mkv": return .video(.mkv)
        case "webm": return .video(.webm)
        case "avi": return .video(.avi)

        // Audio
        case "mp3": return .audio(.mp3)
        case "m4a": return .audio(.m4a)
        case "wav": return .audio(.wav)
        case "aac": return .audio(.aac)
        case "flac": return .audio(.flac)
        case "aiff", "aif": return .audio(.aiff)
        case "ogg": return .audio(.ogg)

        // PDF
        case "pdf": return .pdf

        // Archives
        case "zip", "tar", "gz", "bz2", "7z", "rar":
            return .archive

        // Documents
        case "txt": return .document(.txt)
        case "md", "markdown": return .document(.markdown)
        case "rtf": return .document(.rtf)
        case "docx": return .document(.docx)
        case "csv": return .document(.csv)
        case "json": return .document(.json)

        default:
            break
        }

        // 2. Fallback to UniformTypeIdentifier conformance
        if let utType = UTType(filenameExtension: pathExtension) {
            if utType.conforms(to: .image) {
                return .image(detectImageSubtype(extensionName: pathExtension))
            } else if utType.conforms(to: .movie) || utType.conforms(to: .video) {
                return .video(detectVideoSubtype(extensionName: pathExtension))
            } else if utType.conforms(to: .audio) {
                return .audio(detectAudioSubtype(extensionName: pathExtension))
            } else if utType.conforms(to: .pdf) {
                return .pdf
            } else if utType.conforms(to: .archive) {
                return .archive
            } else if utType.conforms(to: .text) || utType.conforms(to: .plainText) {
                return .document(detectDocumentSubtype(extensionName: pathExtension))
            }
        }

        return .unknown(extensionName: pathExtension)
    }

    private func detectImageSubtype(extensionName: String) -> ImageSubtype {
        switch extensionName {
        case "jpg", "jpeg": return .jpeg
        case "png": return .png
        case "webp": return .webp
        case "heic", "heif": return .heic
        case "tif", "tiff": return .tiff
        case "gif": return .gif
        case "svg": return .svg
        case "bmp": return .bmp
        default: return ImageSubtype(rawValue: extensionName) ?? .other
        }
    }

    private func detectVideoSubtype(extensionName: String) -> VideoSubtype {
        VideoSubtype(rawValue: extensionName) ?? .other
    }

    private func detectAudioSubtype(extensionName: String) -> AudioSubtype {
        switch extensionName {
        case "aif", "aiff": return .aiff
        default: return AudioSubtype(rawValue: extensionName) ?? .other
        }
    }

    private func detectDocumentSubtype(extensionName: String) -> DocumentSubtype {
        DocumentSubtype(rawValue: extensionName) ?? .other
    }
}
