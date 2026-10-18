import Foundation
import Observation
import AppKit

// MARK: - History Item Model
public struct HistoryItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let filename: String
    public let fileCount: Int
    public let operationTitle: String
    public let operationIcon: String
    public let timestamp: Date
    public let status: String // "completed", "failed", "cancelled"
    public let outputURL: URL?
    public let outputSize: Int64?
    public let duration: TimeInterval?
    public let errorMessage: String?

    public init(
        id: UUID = UUID(),
        filename: String,
        fileCount: Int = 1,
        operationTitle: String,
        operationIcon: String = "gearshape",
        timestamp: Date = Date(),
        status: String,
        outputURL: URL? = nil,
        outputSize: Int64? = nil,
        duration: TimeInterval? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.filename = filename
        self.fileCount = fileCount
        self.operationTitle = operationTitle
        self.operationIcon = operationIcon
        self.timestamp = timestamp
        self.status = status
        self.outputURL = outputURL
        self.outputSize = outputSize
        self.duration = duration
        self.errorMessage = errorMessage
    }

    public var isSuccess: Bool {
        status == "completed"
    }

    public var isFailed: Bool {
        status == "failed"
    }

    public var isCancelled: Bool {
        status == "cancelled"
    }
}

// MARK: - Persistent History Store
@Observable
public final class JobHistoryStore: @unchecked Sendable {
    public static let shared = JobHistoryStore()

    public private(set) var items: [HistoryItem] = []

    private let fileURL: URL
    private let lock = NSLock()
    private let maxEntries = 100

    public init(customFileURL: URL? = nil) {
        if let customFileURL {
            self.fileURL = customFileURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            let folder = appSupport.appendingPathComponent("ShiftKit", isDirectory: true)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            self.fileURL = folder.appendingPathComponent("history.json")
        }
        loadFromDisk()
    }

    public func record(job: ConversionJob) {
        let statusStr: String
        var errDesc: String?
        var outURL: URL?
        var outSize: Int64?
        var dur: TimeInterval?

        switch job.status {
        case .completed(let url, let d, let s):
            statusStr = "completed"
            outURL = url
            outSize = s
            dur = d
        case .failed(let err):
            statusStr = "failed"
            errDesc = err.userFacingDescription
        case .cancelled:
            statusStr = "cancelled"
        default:
            return // Active jobs are not recorded to persistent completed history
        }

        let item = HistoryItem(
            id: job.id,
            filename: job.sourceFileName,
            fileCount: job.inputs.count,
            operationTitle: job.actionTitle,
            operationIcon: job.operation.systemIcon,
            timestamp: job.completedAt ?? Date(),
            status: statusStr,
            outputURL: outURL,
            outputSize: outSize,
            duration: dur,
            errorMessage: errDesc
        )

        lock.lock()
        items.removeAll(where: { $0.id == item.id })
        items.insert(item, at: 0)
        if items.count > maxEntries {
            items = Array(items.prefix(maxEntries))
        }
        lock.unlock()

        saveToDisk()
    }

    public func recordDirect(item: HistoryItem) {
        lock.lock()
        items.removeAll(where: { $0.id == item.id })
        items.insert(item, at: 0)
        if items.count > maxEntries {
            items = Array(items.prefix(maxEntries))
        }
        lock.unlock()
        saveToDisk()
    }

    public func clearHistory() {
        lock.lock()
        items.removeAll()
        lock.unlock()
        saveToDisk()
    }

    public func removeItem(id: UUID) {
        lock.lock()
        items.removeAll(where: { $0.id == id })
        lock.unlock()
        saveToDisk()
    }

    @MainActor
    public func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    // MARK: - Disk Persistence
    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let loaded = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            return
        }
        lock.lock()
        self.items = loaded
        lock.unlock()
    }

    private func saveToDisk() {
        lock.lock()
        let snapshot = self.items
        lock.unlock()

        Task.detached(priority: .background) { [fileURL = self.fileURL] in
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
