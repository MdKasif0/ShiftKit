import Foundation

// MARK: - Job Status
public enum JobStatus: Hashable, Sendable {
    case queued
    case processing(progress: Double?, stage: String)
    case completed(outputURL: URL, duration: TimeInterval, outputSize: Int64)
    case failed(error: ShiftKitError)
    case cancelled

    public var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .queued, .processing:
            return false
        }
    }

    public var displayText: String {
        switch self {
        case .queued:
            return "Queued"
        case .processing(let progress, let stage):
            if let progress {
                let percent = Int((progress * 100).clamped(to: 0...100))
                return "\(stage) (\(percent)%)"
            } else {
                return "\(stage) (Processing...)"
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

// MARK: - Conversion Job
public struct ConversionJob: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let request: ConversionRequest
    public var status: JobStatus
    public let createdAt: Date
    public var startedAt: Date?
    public var completedAt: Date?

    public init(
        id: UUID = UUID(),
        request: ConversionRequest,
        status: JobStatus = .queued,
        createdAt: Date = Date(),
        startedAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.request = request
        self.status = status
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.completedAt = completedAt
    }

    public var sourceFileName: String {
        request.sourceURL.lastPathComponent
    }

    public var actionTitle: String {
        request.action.title
    }

    public var outputURL: URL? {
        if case .completed(let url, _, _) = status {
            return url
        }
        return nil
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
