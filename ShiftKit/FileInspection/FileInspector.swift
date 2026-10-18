import Foundation
import CoreGraphics
import ImageIO
import AVFoundation
import PDFKit
import UniformTypeIdentifiers

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
        // 1. Verify existence & type
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw ShiftKitError.fileNotFound(url)
        }
        guard !isDirectory.boolValue else {
            throw ShiftKitError.conversionFailed(reason: "Folders and directories cannot be processed directly as files. Please select individual files or compress to a ZIP archive.")
        }

        // 2. Format & Type Detection via Magic Signatures and Inspection
        let detectedType = typeDetector.detectType(for: url)
        let actualFormat = typeDetector.detectActualFormat(for: url)
        let mismatchInfo = typeDetector.checkFormatMismatch(for: url)

        // 3. System Attributes
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        let fileSize = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        let createdDate = attributes?[.creationDate] as? Date
        let modifiedDate = attributes?[.modificationDate] as? Date

        // 4. UTI & MIME Type Resolution
        var resolvedUTI: String?
        if let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
           let contentType = resourceValues.contentType {
            resolvedUTI = contentType.identifier
        } else {
            resolvedUTI = actualFormat?.uti ?? UTType(filenameExtension: url.pathExtension)?.identifier
        }

        let resolvedMIME: String? = {
            if let mime = actualFormat?.mimeType { return mime }
            if let uti = resolvedUTI, let utType = UTType(uti) {
                return utType.preferredMIMEType
            }
            return nil
        }()

        // 5. Deep Format-Specific Inspection
        var pixelWidth: Int?
        var pixelHeight: Int?
        var colorSpace: String?
        var hasAlphaChannel = false

        var durationSeconds: Double?
        var audioChannels: Int?
        var audioSampleRate: Double?
        let audioBitrate: Int? = nil
        var audioCodec: String?
        var videoFrameRate: Double?
        var videoCodec: String?

        var pageCount: Int?
        var isEncrypted = false
        var documentTitle: String?
        var documentAuthor: String?

        // A. Image Inspection via ImageIO
        if case .image = detectedType {
            if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
               let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] {
                pixelWidth = properties[kCGImagePropertyPixelWidth] as? Int
                pixelHeight = properties[kCGImagePropertyPixelHeight] as? Int
                colorSpace = properties[kCGImagePropertyColorModel] as? String
                hasAlphaChannel = (properties[kCGImagePropertyHasAlpha] as? Bool) ?? false
            }
        }

        // B. Audio & Video Inspection via AVFoundation
        if case .video = detectedType {
            let asset = AVURLAsset(url: url)
            if let duration = try? await asset.load(.duration) {
                let seconds = CMTimeGetSeconds(duration)
                if seconds.isFinite && seconds > 0 { durationSeconds = seconds }
            }

            // Video tracks
            if let videoTracks = try? await asset.loadTracks(withMediaType: .video),
               let firstVideoTrack = videoTracks.first {
                if let naturalSize = try? await firstVideoTrack.load(.naturalSize) {
                    pixelWidth = Int(naturalSize.width)
                    pixelHeight = Int(naturalSize.height)
                }
                if let nominalFps = try? await firstVideoTrack.load(.nominalFrameRate) {
                    videoFrameRate = Double(nominalFps)
                }
                videoCodec = "H.264 / HEVC"
            }

            // Audio tracks in video
            if let audioTracks = try? await asset.loadTracks(withMediaType: .audio),
               let firstAudioTrack = audioTracks.first {
                if let formatDescriptions = try? await firstAudioTrack.load(.formatDescriptions) {
                    if let firstDesc = formatDescriptions.first {
                        let basic = CMAudioFormatDescriptionGetStreamBasicDescription(firstDesc)
                        if let asbd = basic?.pointee {
                            audioChannels = Int(asbd.mChannelsPerFrame)
                            audioSampleRate = asbd.mSampleRate
                        }
                    }
                }
            }
        } else if case .audio = detectedType {
            let asset = AVURLAsset(url: url)
            if let duration = try? await asset.load(.duration) {
                let seconds = CMTimeGetSeconds(duration)
                if seconds.isFinite && seconds > 0 { durationSeconds = seconds }
            }

            if let audioTracks = try? await asset.loadTracks(withMediaType: .audio),
               let firstAudioTrack = audioTracks.first {
                if let formatDescriptions = try? await firstAudioTrack.load(.formatDescriptions) {
                    if let firstDesc = formatDescriptions.first {
                        let basic = CMAudioFormatDescriptionGetStreamBasicDescription(firstDesc)
                        if let asbd = basic?.pointee {
                            audioChannels = Int(asbd.mChannelsPerFrame)
                            audioSampleRate = asbd.mSampleRate
                        }
                    }
                }
            }
        }

        // Fallback to FFmpeg inspection if duration or dimensions are missing
        if (durationSeconds == nil || pixelWidth == nil), (detectedType.isMedia) {
            if let ffmpegMeta = try? await FFmpegEngine().inspectMetadata(url: url) {
                if durationSeconds == nil && ffmpegMeta.duration > 0 {
                    durationSeconds = ffmpegMeta.duration
                }
                if pixelWidth == nil, let w = ffmpegMeta.videoWidth, w > 0 {
                    pixelWidth = w
                    pixelHeight = ffmpegMeta.videoHeight
                }
                if videoCodec == nil { videoCodec = ffmpegMeta.videoCodec }
                if audioCodec == nil { audioCodec = ffmpegMeta.audioCodec }
                if audioChannels == nil { audioChannels = ffmpegMeta.audioChannels }
                if audioSampleRate == nil { audioSampleRate = ffmpegMeta.audioSampleRate }
                if documentTitle == nil { documentTitle = ffmpegMeta.title }
                if documentAuthor == nil { documentAuthor = ffmpegMeta.artist }
            }
        }

        // C. PDF Inspection via PDFKit
        if case .pdf = detectedType {
            if let pdf = PDFDocument(url: url) {
                pageCount = pdf.pageCount
                isEncrypted = pdf.isEncrypted
                documentTitle = pdf.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
                documentAuthor = pdf.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String
            }
        }

        let metadata = FileMetadata(
            fileSize: fileSize,
            fileExtension: url.pathExtension,
            uti: resolvedUTI,
            mimeType: resolvedMIME,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            colorSpace: colorSpace,
            hasAlphaChannel: hasAlphaChannel,
            durationSeconds: durationSeconds,
            audioChannels: audioChannels,
            audioSampleRate: audioSampleRate,
            audioBitrate: audioBitrate,
            audioCodec: audioCodec,
            videoFrameRate: videoFrameRate,
            videoCodec: videoCodec,
            pageCount: pageCount,
            isEncrypted: isEncrypted,
            documentTitle: documentTitle,
            documentAuthor: documentAuthor,
            isFormatExtensionMismatch: mismatchInfo.hasMismatch,
            detectedFormat: actualFormat,
            createdDate: createdDate,
            modifiedDate: modifiedDate
        )

        return InspectedFile(
            url: url,
            fileName: url.lastPathComponent,
            fileType: detectedType,
            metadata: metadata
        )
    }
}
