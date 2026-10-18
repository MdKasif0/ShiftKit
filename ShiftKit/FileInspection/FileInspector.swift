import Foundation
import CoreGraphics
import ImageIO
import AVFoundation
import PDFKit

// MARK: - Protocol
public protocol FileInspecting: Sendable {
    func inspect(url: URL) async throws -> InspectedFile
}

// MARK: - Implementation
public final class FileInspector: FileInspecting {
    private let typeDetector: FileTypeDetecting

    public init(typeDetector: FileTypeDetecting = FileTypeDetector()) {
        self.typeDetector = typeDetector
    }

    public func inspect(url: URL) async throws -> InspectedFile {
        // Verify file exists
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            throw ShiftKitError.fileNotFound(url)
        }

        let fileType = typeDetector.detectType(for: url)

        // Read file system attributes
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        let fileSize = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        let createdDate = attributes?[.creationDate] as? Date
        let modifiedDate = attributes?[.modificationDate] as? Date

        var pixelWidth: Int?
        var pixelHeight: Int?
        var durationSeconds: Double?
        var pageCount: Int?

        switch fileType {
        case .image:
            if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
               let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] {
                pixelWidth = properties[kCGImagePropertyPixelWidth] as? Int
                pixelHeight = properties[kCGImagePropertyPixelHeight] as? Int
            }

        case .video, .audio:
            let asset = AVURLAsset(url: url)
            if let duration = try? await asset.load(.duration) {
                let seconds = CMTimeGetSeconds(duration)
                if seconds.isFinite && seconds > 0 {
                    durationSeconds = seconds
                }
            }
            if case .video = fileType {
                if let tracks = try? await asset.loadTracks(withMediaType: .video),
                   let firstTrack = tracks.first,
                   let naturalSize = try? await firstTrack.load(.naturalSize) {
                    pixelWidth = Int(naturalSize.width)
                    pixelHeight = Int(naturalSize.height)
                }
            }

        case .pdf:
            if let pdf = PDFDocument(url: url) {
                pageCount = pdf.pageCount
            }

        default:
            break
        }

        let metadata = FileMetadata(
            fileSize: fileSize,
            fileExtension: url.pathExtension,
            uti: nil,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            durationSeconds: durationSeconds,
            pageCount: pageCount,
            createdDate: createdDate,
            modifiedDate: modifiedDate
        )

        return InspectedFile(
            url: url,
            fileName: url.lastPathComponent,
            fileType: fileType,
            metadata: metadata
        )
    }
}
