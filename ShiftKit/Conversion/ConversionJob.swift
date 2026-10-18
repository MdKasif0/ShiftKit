import Foundation

// MARK: - Job Status
public enum JobStatus: Hashable, Sendable {
    case queued
    case inspecting
    case ready
    case running(progress: Double, stage: String)
    case completed(outputURL: URL, duration: TimeInterval, outputSize: Int64)
    case failed(error: ShiftKitError)
    case cancelled

    // Backwards compatibility factory for previous .processing calls
    public static func processing(progress: Double?, stage: String) -> JobStatus {
        .running(progress: progress ?? 0.0, stage: stage)
    }

    public var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .queued, .inspecting, .ready, .running:
            return false
        }
    }

    public var displayText: String {
        switch self {
        case .queued:
            return "Queued"
        case .inspecting:
            return "Inspecting Files..."
        case .ready:
            return "Ready"
        case .running(let progress, let stage):
            let percent = Int((progress * 100).clamped(to: 0...100))
            if progress > 0 {
                return "\(stage) (\(percent)%)"
            } else {
                return "\(stage)..."
            }
        case .completed:
            return "Completed"
        case .failed(let err):
            return "Failed: \(err.localizedDescription)"
        case .cancelled:
            return "Cancelled"
        }
    }
}

// MARK: - Conversion Job Model
public struct ConversionJob: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let inputs: [URL]
    public let operation: ConversionAction
    public var outputFormat: OutputFormat?
    public var destinationURL: URL?
    public var configuration: ConversionOptions
    public var status: JobStatus
    public let createdAt: Date
    public var startedAt: Date?
    public var completedAt: Date?

    // Backwards compatible request wrapper
    public var request: ConversionRequest {
        ConversionRequest(
            sourceURL: inputs.first ?? URL(fileURLWithPath: "/dev/null"),
            fileType: .unknown(extensionName: inputs.first?.pathExtension ?? ""),
            action: operation,
            destinationURL: destinationURL,
            options: [:],
            conversionOptions: configuration
        )
    }

    public init(
        id: UUID = UUID(),
        inputs: [URL],
        operation: ConversionAction,
        outputFormat: OutputFormat? = nil,
        destinationURL: URL? = nil,
        configuration: ConversionOptions = .default,
        status: JobStatus = .queued,
        createdAt: Date = Date(),
        startedAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.inputs = inputs
        self.operation = operation
        self.outputFormat = outputFormat ?? OutputFormat.find(byExtension: operation.targetFormat ?? "")
        self.destinationURL = destinationURL
        self.configuration = configuration
        self.status = status
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.completedAt = completedAt
    }

    // Convenience initializer for ConversionRequest
    public init(
        id: UUID = UUID(),
        request: ConversionRequest,
        status: JobStatus = .queued,
        createdAt: Date = Date(),
        startedAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.inputs = [request.sourceURL]
        self.operation = request.action
        self.outputFormat = OutputFormat.find(byExtension: request.action.targetFormat ?? "")
        self.destinationURL = request.destinationURL
        self.configuration = request.conversionOptions
        self.status = status
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.completedAt = completedAt
    }

    public var progress: Double {
        switch status {
        case .running(let p, _):
            return p
        case .completed:
            return 1.0
        default:
            return 0.0
        }
    }

    public var isCancelled: Bool {
        status == .cancelled
    }

    public var error: ShiftKitError? {
        if case .failed(let err) = status {
            return err
        }
        return nil
    }

    public var sourceFileName: String {
        inputs.first?.lastPathComponent ?? "File"
    }

    public var actionTitle: String {
        operation.title
    }

    public var outputURL: URL? {
        if case .completed(let url, _, _) = status {
            return url
        }
        return destinationURL
    }

    public var outputSize: Int64? {
        if case .completed(_, _, let size) = status, size > 0 {
            return size
        }
        return nil
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
