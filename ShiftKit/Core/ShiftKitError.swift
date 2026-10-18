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
        }
    }
}
