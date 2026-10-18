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
    case permissionDenied(URL)
    case outputConflict(URL)
    case invalidInput(reason: String)

    public var errorDescription: String? {
        userFacingDescription
    }

    /// User-friendly, non-technical description of what occurred without raw command-line dumps.
    public var userFacingDescription: String {
        switch self {
        case .fileNotFound(let url):
            return "ShiftKit could not find \"\(url.lastPathComponent)\"."
        case .unsupportedFileType(let url):
            return "The file format of \"\(url.lastPathComponent)\" is not supported for this operation."
        case .unsupportedAction(let action):
            return "The requested action \"\(action)\" cannot be applied to this file type."
        case .engineNotAvailable(let engine):
            return "A required local tool (\(engine)) is not installed or available on your Mac."
        case .destinationUnwritable(let url):
            return "ShiftKit does not have write access to the destination folder at \"\(url.path)\"."
        case .conversionFailed(let reason):
            return "The operation could not be completed: \(reason)"
        case .processExecutionFailed(let code, let msg):
            let clean = msg.components(separatedBy: "\n").first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? "Error"
            return "The conversion process encountered an issue (code \(code)): \(clean)"
        case .cancelled:
            return "Operation was cancelled."
        case .unsupportedCodecOrFormat(let codec, let format):
            let desc = !codec.isEmpty ? codec : format
            return "The format or codec \"\(desc)\" is not supported by your local configuration."
        case .insufficientDiskSpace(let needed, let available):
            let neededStr = ByteCountFormatter.string(fromByteCount: needed, countStyle: .file)
            let availableStr = ByteCountFormatter.string(fromByteCount: available, countStyle: .file)
            return "Your Mac needs approximately \(neededStr) of free space to process this file, but only \(availableStr) is available."
        case .corruptMedia(let reason):
            return "The file appears damaged or incomplete: \(reason)"
        case .invalidTimestamp(let start, let end, let duration):
            return String(format: "The selected time range (%.1fs to %.1fs) exceeds the file duration of %.1fs.", start, end, duration)
        case .incompatibleStreams(let reason):
            return "The files have incompatible media streams that cannot be joined: \(reason)"
        case .permissionDenied(let url):
            return "Access to \"\(url.lastPathComponent)\" was denied by macOS security."
        case .outputConflict(let url):
            return "A file already exists at \"\(url.lastPathComponent)\" and conflict policy prevents overwriting."
        case .invalidInput(let reason):
            return "The input file is invalid: \(reason)"
        }
    }

    /// Actionable next step for the user to resolve the problem.
    public var recoverySuggestion: String {
        switch self {
        case .fileNotFound:
            return "Verify that the file still exists and has not been moved, renamed, or deleted."
        case .unsupportedFileType:
            return "Check the Supported Formats in Settings or convert the file to a standard format first."
        case .unsupportedAction:
            return "Choose a different action from the radial menu that matches this file type."
        case .engineNotAvailable:
            return "Install the optional local tool via Homebrew (e.g. brew install ffmpeg) or LibreOffice, then retry."
        case .destinationUnwritable, .permissionDenied:
            return "Grant ShiftKit access in System Settings > Privacy & Security, or choose a folder inside your Downloads or Documents."
        case .conversionFailed, .processExecutionFailed:
            return "Verify the input file opens in Preview or QuickTime, or try using an alternative output format."
        case .cancelled:
            return "You can drag the file onto ShiftKit to start the operation again."
        case .unsupportedCodecOrFormat:
            return "Select a widely compatible target format such as MP4, WebM, PNG, or MP3."
        case .insufficientDiskSpace:
            return "Free up disk space on this volume before retrying the conversion."
        case .corruptMedia, .invalidInput:
            return "Re-export or re-download the file, or inspect it with another player to confirm it is not corrupted."
        case .invalidTimestamp:
            return "Adjust the trim start and end handles in the video editor to fall within the clip."
        case .incompatibleStreams:
            return "Ensure all video or audio clips have matching dimensions, frame rates, and sample rates before merging."
        case .outputConflict:
            return "Change the Conflict Behavior in ShiftKit Settings to Auto-number or select a different output folder."
        }
    }
}
