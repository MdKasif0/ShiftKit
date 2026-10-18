import Foundation
import AVFoundation

public final class AVFoundationEngine: ConversionEngine {
    public let engineID = "com.shiftkit.engine.avfoundation"
    public let engineName = "AVFoundation Native Media"

    public init() {}

    public func canHandle(action: ConversionAction, fileType: FileType) -> Bool {
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
        progressHandler: @Sendable @escaping (Double, String) -> Void
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

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to initialize AVAssetExportSession.")
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = outputFileType
        exportSession.shouldOptimizeForNetworkUse = true

        progressHandler(0.3, "Exporting media...")

        // Monitor progress via Task while export is running
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                while exportSession.status == .waiting || exportSession.status == .exporting {
                    let progress = Double(exportSession.progress)
                    progressHandler(0.3 + (progress * 0.6), "Encoding media...")
                    try await Task.sleep(nanoseconds: 200_000_000)
                }
            }

            group.addTask {
                await exportSession.export()
                if let error = exportSession.error {
                    throw ShiftKitError.conversionFailed(reason: error.localizedDescription)
                }
                if exportSession.status == .failed {
                    throw ShiftKitError.conversionFailed(reason: "AVAssetExportSession encountered an unknown failure.")
                }
                if exportSession.status == .cancelled {
                    throw ShiftKitError.cancelled
                }
            }

            // Wait for completion task
            try await group.next()
            group.cancelAll()
        }

        progressHandler(1.0, "Completed")
        return outputURL
    }
}
