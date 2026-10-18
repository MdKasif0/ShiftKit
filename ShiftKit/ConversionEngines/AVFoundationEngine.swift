import Foundation
import AVFoundation

public final class AVFoundationEngine: ConversionEngine {
    public let engineID = "com.shiftkit.engine.avfoundation"
    public let engineName = "AVFoundation Native Media"

    public init() {}

    public func canHandle(action: ConversionAction, fileType: FileType) -> Bool {
        if action.id == "vid_to_gif" || action.targetFormat == "gif" || action.targetFormat == "webm" || action.id == "audio_to_mp3" {
            return false // Delegated to FFmpeg
        }
        switch fileType {
        case .video, .audio:
            // AVFoundation handles standard Apple formats (MP4, MOV, M4A, etc.)
            return true
        default:
            return false
        }
    }

    public func execute(
        request: ConversionRequest,
        outputURL: URL,
        progressHandler: @Sendable @escaping (Double?, String) -> Void
    ) async throws -> URL {
        progressHandler(0.1, "Loading media asset...")

        let asset = AVURLAsset(url: request.sourceURL)
        let isExportable = try await asset.load(.isExportable)
        guard isExportable else {
            throw ShiftKitError.conversionFailed(reason: "Media asset is not exportable via AVFoundation.")
        }

        // Determine preset
        let preset: String
        let outputFileType: AVFileType

        switch request.action.id {
        case "vid_extract_audio", "audio_to_m4a":
            preset = AVAssetExportPresetAppleM4A
            outputFileType = .m4a
        case "vid_compress":
            preset = AVAssetExportPreset1280x720
            outputFileType = .mp4
        default:
            preset = AVAssetExportPresetHighestQuality
            outputFileType = .mp4
        }

        guard outputURL.standardizedFileURL.path != request.sourceURL.standardizedFileURL.path else {
            throw ShiftKitError.conversionFailed(reason: "Output destination cannot overwrite original source file.")
        }

        let parentDir = outputURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDir.path) {
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        let tempURL = parentDir.appendingPathComponent(".tmp_avf_\(UUID().uuidString.prefix(8)).\(outputURL.pathExtension)")
        if FileManager.default.fileExists(atPath: tempURL.path) {
            try? FileManager.default.removeItem(at: tempURL)
        }

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to initialize AVAssetExportSession.")
        }

        exportSession.outputURL = tempURL
        exportSession.outputFileType = outputFileType
        exportSession.shouldOptimizeForNetworkUse = true

        progressHandler(0.3, "Exporting media...")

        return try await withTaskCancellationHandler {
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        while exportSession.status == .waiting || exportSession.status == .exporting {
                            if Task.isCancelled {
                                exportSession.cancelExport()
                                break
                            }
                            let progress = Double(exportSession.progress)
                            progressHandler(0.3 + (progress * 0.6), "Encoding media...")
                            try await Task.sleep(nanoseconds: 200_000_000)
                        }
                    }

                    group.addTask {
                        await exportSession.export()
                        if Task.isCancelled || exportSession.status == .cancelled {
                            throw ShiftKitError.cancelled
                        }
                        if let error = exportSession.error {
                            throw ShiftKitError.conversionFailed(reason: error.localizedDescription)
                        }
                        if exportSession.status == .failed {
                            throw ShiftKitError.conversionFailed(reason: "AVAssetExportSession encountered an unknown failure.")
                        }
                    }

                    try await group.next()
                    group.cancelAll()
                }

                if Task.isCancelled {
                    try? FileManager.default.removeItem(at: tempURL)
                    throw ShiftKitError.cancelled
                }

                let fm = FileManager.default
                if fm.fileExists(atPath: outputURL.path) {
                    try fm.removeItem(at: outputURL)
                }
                try fm.moveItem(at: tempURL, to: outputURL)

                progressHandler(1.0, "Completed")
                return outputURL
            } catch {
                try? FileManager.default.removeItem(at: tempURL)
                throw error
            }
        } onCancel: {
            exportSession.cancelExport()
            try? FileManager.default.removeItem(at: tempURL)
        }
    }
}
