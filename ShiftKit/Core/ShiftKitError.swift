import Foundation

public enum ShiftKitError: LocalizedError, Hashable, Sendable {
    case fileNotFound(URL)
    case unsupportedFileType(URL)
    case unsupportedAction(String)
    case engineNotAvailable(engineName: String)
    case destinationUnwritable(URL)
    case conversionFailed(reason: String)
    case processExecutionFailed(exitCode: Int32, message: String)
    case cancelled
    case unsupportedCodecOrFormat(codec: String, format: String)
    case insufficientDiskSpace(needed: Int64, available: Int64)
    case corruptMedia(reason: String)
    case invalidTimestamp(start: Double, end: Double, duration: Double)
    case incompatibleStreams(reason: String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "File could not be found at path: \(url.path)"
        case .unsupportedFileType(let url):
            return "The file type for '\(url.lastPathComponent)' is not supported."
        case .unsupportedAction(let action):
            return "The requested action '\(action)' is not supported for this file type."
        case .engineNotAvailable(let engine):
            return "The conversion engine '\(engine)' is not configured or available."
        case .destinationUnwritable(let url):
            return "Unable to write output file to destination folder: \(url.path)"
        case .conversionFailed(let reason):
            return "Operation failed: \(reason)"
        case .processExecutionFailed(let code, let msg):
            return "Process failed with exit code \(code): \(msg)"
        case .cancelled:
            return "Operation was cancelled by user."
        case .unsupportedCodecOrFormat(let codec, let format):
            return "The requested codec '\(codec)' or container format '\(format)' is not supported by the local engine."
        case .insufficientDiskSpace(let needed, let available):
            let neededMB = ByteCountFormatter.string(fromByteCount: needed, countStyle: .file)
            let availableMB = ByteCountFormatter.string(fromByteCount: available, countStyle: .file)
            return "Insufficient disk space: requires approximately \(neededMB), but only \(availableMB) is available."
        case .corruptMedia(let reason):
            return "Media file appears corrupt or unreadable: \(reason)"
        case .invalidTimestamp(let start, let end, let duration):
            return String(format: "Invalid trim timestamps: start=%.2fs, end=%.2fs (total duration: %.2fs)", start, end, duration)
        case .incompatibleStreams(let reason):
            return "Incompatible media streams: \(reason)"
        }
    }
}
