import Foundation
import UniformTypeIdentifiers

// MARK: - Protocol
public protocol FileTypeDetecting: Sendable {
    func detectType(for url: URL) -> FileType
    func detectActualFormat(for url: URL) -> OutputFormat?
    func sniffHeader(data: Data) -> OutputFormat?
    func checkFormatMismatch(for url: URL) -> (hasMismatch: Bool, actualFormat: OutputFormat?, declaredExtension: String)
}

// MARK: - Implementation
public final class FileTypeDetector: FileTypeDetecting {
    public init() {}

    /// Primary detection combining header inspection, UTI, and extension fallback.
    public func detectType(for url: URL) -> FileType {
        if let actual = detectActualFormat(for: url) {
            return mapFormatToFileType(actual)
        }
        return detectTypeFromExtensionAndUTI(pathExtension: url.pathExtension.lowercased())
    }

    /// Sniffs the beginning of the actual file to inspect binary magic numbers.
    public func detectActualFormat(for url: URL) -> OutputFormat? {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return OutputFormat.find(byExtension: url.pathExtension)
        }

        defer { try? fileHandle.close() }

        guard let headerData = try? fileHandle.read(upToCount: 64), !headerData.isEmpty else {
            return OutputFormat.find(byExtension: url.pathExtension)
        }

        if let sniffed = sniffHeader(data: headerData) {
            return sniffed
        }

        // If binary sniffing did not find a match, check UTI from system resource values
        if let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
           let utType = resourceValues.contentType {
            if let matched = OutputFormat.find(byUTI: utType.identifier) {
                return matched
            }
        }

        return OutputFormat.find(byExtension: url.pathExtension)
    }

    /// Sniffs magic signatures from raw initial bytes of a stream or file.
    public func sniffHeader(data: Data) -> OutputFormat? {
        let count = data.count
        guard count >= 3 else { return nil }

        let bytes = [UInt8](data.prefix(64))

        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if count >= 8, bytes[0] == 0x89, bytes[1] == 0x50, bytes[2] == 0x4E, bytes[3] == 0x47,
           bytes[4] == 0x0D, bytes[5] == 0x0A, bytes[6] == 0x1A, bytes[7] == 0x0A {
            return .png
        }

        // JPEG: FF D8 FF
        if bytes[0] == 0xFF, bytes[1] == 0xD8, bytes[2] == 0xFF {
            return .jpeg
        }

        // GIF: GIF87a or GIF89a (47 49 46 38 37/39 61)
        if count >= 6, bytes[0] == 0x47, bytes[1] == 0x49, bytes[2] == 0x46,
           bytes[3] == 0x38, (bytes[4] == 0x37 || bytes[4] == 0x39), bytes[5] == 0x61 {
            return .gif
        }

        // WebP: RIFF .... WEBP
        if count >= 12, bytes[0] == 0x52, bytes[1] == 0x49, bytes[2] == 0x46, bytes[3] == 0x46,
           bytes[8] == 0x57, bytes[9] == 0x45, bytes[10] == 0x42, bytes[11] == 0x50 {
            return .webp
        }

        // WAV: RIFF .... WAVE
        if count >= 12, bytes[0] == 0x52, bytes[1] == 0x49, bytes[2] == 0x46, bytes[3] == 0x46,
           bytes[8] == 0x57, bytes[9] == 0x41, bytes[10] == 0x56, bytes[11] == 0x45 {
            return .wav
        }

        // AVI: RIFF .... AVI 
        if count >= 12, bytes[0] == 0x52, bytes[1] == 0x49, bytes[2] == 0x46, bytes[3] == 0x46,
           bytes[8] == 0x41, bytes[9] == 0x56, bytes[10] == 0x49, bytes[11] == 0x20 {
            return .avi
        }

        // AIFF: FORM .... AIFF
        if count >= 12, bytes[0] == 0x46, bytes[1] == 0x4F, bytes[2] == 0x52, bytes[3] == 0x4D,
           bytes[8] == 0x41, bytes[9] == 0x49, bytes[10] == 0x46, bytes[11] == 0x46 {
            return .aiff
        }

        // TIFF: 49 49 2A 00 (little endian) or 4D 4D 00 2A (big endian)
        if count >= 4 {
            if (bytes[0] == 0x49 && bytes[1] == 0x49 && bytes[2] == 0x2A && bytes[3] == 0x00) ||
               (bytes[0] == 0x4D && bytes[1] == 0x4D && bytes[2] == 0x00 && bytes[3] == 0x2A) {
                return .tiff
            }
        }

        // PDF: %PDF- (25 50 44 46 2D)
        if count >= 5, bytes[0] == 0x25, bytes[1] == 0x50, bytes[2] == 0x44, bytes[3] == 0x46, bytes[4] == 0x2D {
            return .pdf
        }

        // ZIP: 50 4B 03 04
        if count >= 4, bytes[0] == 0x50, bytes[1] == 0x4B, bytes[2] == 0x03, bytes[3] == 0x04 {
            return .zip
        }

        // FLAC: 66 4C 61 43 ("fLaC")
        if count >= 4, bytes[0] == 0x66, bytes[1] == 0x4C, bytes[2] == 0x61, bytes[3] == 0x43 {
            return .flac
        }

        // OGG / Opus: 4F 67 67 53 ("OggS")
        if count >= 4, bytes[0] == 0x4F, bytes[1] == 0x67, bytes[2] == 0x67, bytes[3] == 0x53 {
            // Check if OpusHead is present within header
            if let str = String(data: data.prefix(40), encoding: .ascii), str.contains("OpusHead") {
                return .opus
            }
            return .ogg
        }

        // EBML (Matroska / WebM): 1A 45 DF A3
        if count >= 4, bytes[0] == 0x1A, bytes[1] == 0x45, bytes[2] == 0xDF, bytes[3] == 0xA3 {
            if let str = String(data: data.prefix(64), encoding: .ascii) {
                if str.contains("webm") {
                    return .webm
                } else {
                    return .mkv
                }
            }
            return .mkv
        }

        // AAC ADTS Sync Word: 0xFFF (0xFF followed by 0xF0..0xFF)
        if count >= 2, bytes[0] == 0xFF, (bytes[1] & 0xF6) == 0xF0 {
            return .aac
        }

        // MP3: ID3 header (49 44 33) or sync bytes (FF FB / FF F3 / FF F2)
        if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) ||
           (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
            return .mp3
        }

        // ISO Base Media (MP4, MOV, M4A, HEIC) with 'ftyp' at offset 4..7
        if count >= 12, bytes[4] == 0x66, bytes[5] == 0x74, bytes[6] == 0x79, bytes[7] == 0x70 {
            let brandData = data.subdata(in: 8..<12)
            if let brand = String(data: brandData, encoding: .ascii)?.lowercased() {
                if brand.contains("heic") || brand.contains("mif1") || brand.contains("msf1") {
                    return .heic
                } else if brand.contains("qt") {
                    return .mov
                } else if brand.contains("m4a") {
                    return .m4a
                } else {
                    return .mp4
                }
            }
            return .mp4
        }

        return nil
    }

    /// Checks if the declared file extension conflicts with the actual inspected container format.
    public func checkFormatMismatch(for url: URL) -> (hasMismatch: Bool, actualFormat: OutputFormat?, declaredExtension: String) {
        let declaredExt = url.pathExtension.lowercased()
        guard let actualFormat = detectActualFormat(for: url) else {
            return (false, nil, declaredExt)
        }

        let isRecognized = actualFormat.recognizedExtensions.contains(declaredExt)
        return (!isRecognized, actualFormat, declaredExt)
    }

    // MARK: - Private Helpers
    private func mapFormatToFileType(_ format: OutputFormat) -> FileType {
        switch format.id {
        case "png": return .image(.png)
        case "jpeg": return .image(.jpeg)
        case "webp": return .image(.webp)
        case "heic": return .image(.heic)
        case "tiff": return .image(.tiff)
        case "gif": return .image(.gif)
        case "mp4": return .video(.mp4)
        case "mov": return .video(.mov)
        case "mkv": return .video(.mkv)
        case "webm": return .video(.webm)
        case "avi": return .video(.avi)
        case "mp3": return .audio(.mp3)
        case "m4a": return .audio(.m4a)
        case "aac": return .audio(.aac)
        case "wav": return .audio(.wav)
        case "flac": return .audio(.flac)
        case "aiff": return .audio(.aiff)
        case "ogg": return .audio(.ogg)
        case "opus": return .audio(.opus)
        case "pdf": return .pdf
        case "zip": return .archive
        case "csv": return .document(.csv)
        case "json": return .document(.json)
        case "txt": return .document(.txt)
        default:
            return detectTypeFromExtensionAndUTI(pathExtension: format.primaryExtension)
        }
    }

    private func detectTypeFromExtensionAndUTI(pathExtension: String) -> FileType {
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
        case "ogg", "oga": return .audio(.ogg)
        case "opus": return .audio(.opus)

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

        // Fallback to UniformTypeIdentifier conformance
        if let utType = UTType(filenameExtension: pathExtension) {
            if utType.conforms(to: .image) {
                return .image(ImageSubtype(rawValue: pathExtension) ?? .other)
            } else if utType.conforms(to: .movie) || utType.conforms(to: .video) {
                return .video(VideoSubtype(rawValue: pathExtension) ?? .other)
            } else if utType.conforms(to: .audio) {
                return .audio(AudioSubtype(rawValue: pathExtension) ?? .other)
            } else if utType.conforms(to: .pdf) {
                return .pdf
            } else if utType.conforms(to: .archive) {
                return .archive
            } else if utType.conforms(to: .text) || utType.conforms(to: .plainText) {
                return .document(DocumentSubtype(rawValue: pathExtension) ?? .other)
            }
        }

        return .unknown(extensionName: pathExtension)
    }
}
