import Foundation
import AppKit

// MARK: - Output Location Strategy
public enum OutputLocationStrategy: Hashable, Sendable {
    case besideOriginal
    case dedicatedFolder(URL)
    case askWhereToSave
}

// MARK: - Protocol
public protocol OutputManaging: Sendable {
    func defaultOutputDirectory() -> URL
    func resolveDestinationURL(
        for sourceURL: URL,
        targetExtension: String?,
        suffix: String?,
        customDirectory: URL?
    ) -> URL
    func resolveDestinationURL(
        for sourceURL: URL,
        targetExtension: String?,
        suffix: String?,
        strategy: OutputLocationStrategy
    ) async throws -> URL
    func resolveDestination(
        for sourceURL: URL,
        targetExtension: String?,
        suffix: String?,
        customDirectory: URL?,
        conflictResolution: FilenameConflictResolution
    ) throws -> URL
    func validateOutput(at url: URL) throws -> Int64
    func createTemporaryOutputURL(for destinationURL: URL) throws -> URL
    func commitTemporaryOutput(temporaryURL: URL, destinationURL: URL) throws
    func cleanupTemporaryOutput(temporaryURL: URL)
    func detectConflicts(
        sources: [URL],
        targetExtension: String?,
        suffix: String?,
        targetDirectory: URL?
    ) -> [URL: [URL]]
    func revealInFinder(url: URL)
    func openFile(url: URL)
}

// MARK: - Implementation
public final class OutputManager: OutputManaging, @unchecked Sendable {
    private let fileManager = FileManager.default
    private let reservationLock = NSLock()
    private var reservedDestinationPaths: Set<String> = []

    public init() {}

    public func defaultOutputDirectory() -> URL {
        let customPath = SettingsStore.shared.outputDirectoryPath
        let expanded = NSString(string: customPath).expandingTildeInPath
        if !expanded.isEmpty {
            let customDir = URL(fileURLWithPath: expanded)
            if !fileManager.fileExists(atPath: customDir.path) {
                try? fileManager.createDirectory(at: customDir, withIntermediateDirectories: true)
            }
            if fileManager.fileExists(atPath: customDir.path) {
                return customDir
            }
        }

        let downloads = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let shiftKitFolder = downloads.appendingPathComponent("ShiftKit", isDirectory: true)

        if !fileManager.fileExists(atPath: shiftKitFolder.path) {
            try? fileManager.createDirectory(at: shiftKitFolder, withIntermediateDirectories: true)
        }
        return shiftKitFolder
    }

    public func resolveDestinationURL(
        for sourceURL: URL,
        targetExtension: String? = nil,
        suffix: String? = nil,
        customDirectory: URL? = nil
    ) -> URL {
        let targetDir = customDirectory ?? defaultOutputDirectory()
        return (try? generateURL(
            sourceURL: sourceURL,
            targetDir: targetDir,
            targetExtension: targetExtension,
            suffix: suffix,
            conflictResolution: .renameWithNumber
        )) ?? targetDir.appendingPathComponent("\(sourceURL.deletingPathExtension().lastPathComponent).\(targetExtension ?? sourceURL.pathExtension)")
    }

    public func resolveDestination(
        for sourceURL: URL,
        targetExtension: String? = nil,
        suffix: String? = nil,
        customDirectory: URL? = nil,
        conflictResolution: FilenameConflictResolution = .renameWithNumber
    ) throws -> URL {
        let targetDir = customDirectory ?? defaultOutputDirectory()
        return try generateURL(
            sourceURL: sourceURL,
            targetDir: targetDir,
            targetExtension: targetExtension,
            suffix: suffix,
            conflictResolution: conflictResolution
        )
    }

    public func resolveDestinationURL(
        for sourceURL: URL,
        targetExtension: String? = nil,
        suffix: String? = nil,
        strategy: OutputLocationStrategy
    ) async throws -> URL {
        switch strategy {
        case .besideOriginal:
            let parentDir = sourceURL.deletingLastPathComponent()
            return try generateURL(
                sourceURL: sourceURL,
                targetDir: parentDir,
                targetExtension: targetExtension,
                suffix: suffix,
                conflictResolution: .renameWithNumber
            )

        case .dedicatedFolder(let folderURL):
            return try generateURL(
                sourceURL: sourceURL,
                targetDir: folderURL,
                targetExtension: targetExtension,
                suffix: suffix,
                conflictResolution: .renameWithNumber
            )

        case .askWhereToSave:
            return try await promptUserForSaveLocation(sourceURL: sourceURL, targetExtension: targetExtension, suffix: suffix)
        }
    }

    /// Validates an exported file: exists, non-empty, and readable.
    public func validateOutput(at url: URL) throws -> Int64 {
        guard fileManager.fileExists(atPath: url.path) else {
            throw ShiftKitError.conversionFailed(reason: "Output file was not created at \(url.lastPathComponent)")
        }
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let size = (attrs[.size] as? NSNumber)?.int64Value, size > 0 else {
            throw ShiftKitError.conversionFailed(reason: "Output file is empty (0 bytes)")
        }
        guard fileManager.isReadableFile(atPath: url.path) else {
            throw ShiftKitError.permissionDenied(url)
        }
        return size
    }

    /// Creates an atomic temporary working file URL in the same directory as the final destination.
    public func createTemporaryOutputURL(for destinationURL: URL) throws -> URL {
        let parentDir = destinationURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        let tempName = ".\(destinationURL.lastPathComponent).tmp-\(UUID().uuidString.prefix(8))"
        return parentDir.appendingPathComponent(tempName)
    }

    /// Atomically commits a completed temporary output file to its destination.
    public func commitTemporaryOutput(temporaryURL: URL, destinationURL: URL) throws {
        defer {
            reservationLock.lock()
            reservedDestinationPaths.remove(destinationURL.path)
            reservationLock.unlock()
        }

        guard destinationURL.standardizedFileURL.path != temporaryURL.standardizedFileURL.path else {
            throw ShiftKitError.conversionFailed(reason: "Temporary and destination output paths cannot be identical.")
        }

        guard fileManager.fileExists(atPath: temporaryURL.path) else {
            throw ShiftKitError.conversionFailed(reason: "Temporary output file missing at \(temporaryURL.path)")
        }

        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                _ = try fileManager.replaceItemAt(destinationURL, withItemAt: temporaryURL)
                return
            } catch {
                try fileManager.removeItem(at: destinationURL)
            }
        }

        try fileManager.moveItem(at: temporaryURL, to: destinationURL)
    }

    /// Cleans up a temporary output file if a conversion job fails or is cancelled.
    public func cleanupTemporaryOutput(temporaryURL: URL) {
        if fileManager.fileExists(atPath: temporaryURL.path) {
            try? fileManager.removeItem(at: temporaryURL)
        }
    }

    /// Detects duplicate destination filenames among a batch of files being processed.
    public func detectConflicts(
        sources: [URL],
        targetExtension: String?,
        suffix: String?,
        targetDirectory: URL?
    ) -> [URL: [URL]] {
        var destinations: [URL: [URL]] = [:]

        for source in sources {
            let baseName = source.deletingPathExtension().lastPathComponent
            let ext = (targetExtension ?? source.pathExtension).lowercased()
            let baseWithSuffix = (suffix != nil && !suffix!.isEmpty) ? "\(baseName)_\(suffix!)" : baseName
            let dir = targetDirectory ?? defaultOutputDirectory()
            let dest = dir.appendingPathComponent("\(baseWithSuffix).\(ext)")

            destinations[dest, default: []].append(source)
        }

        return destinations.filter { $0.value.count > 1 }
    }

    @MainActor
    public func revealInFinder(url: URL) {
        if fileManager.fileExists(atPath: url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            let parent = url.deletingLastPathComponent()
            if fileManager.fileExists(atPath: parent.path) {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: parent.path)
            }
        }
    }

    @MainActor
    public func openFile(url: URL) {
        NSWorkspace.shared.open(url)
    }

    // MARK: - Private Helpers
    private func generateURL(
        sourceURL: URL,
        targetDir: URL,
        targetExtension: String?,
        suffix: String?,
        conflictResolution: FilenameConflictResolution
    ) throws -> URL {
        if !fileManager.fileExists(atPath: targetDir.path) {
            try? fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
        }

        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = (targetExtension ?? sourceURL.pathExtension).lowercased()

        let baseWithSuffix: String
        if let suffix, !suffix.isEmpty {
            baseWithSuffix = "\(baseName)_\(suffix)"
        } else {
            baseWithSuffix = baseName
        }

        let standard = targetDir.appendingPathComponent("\(baseWithSuffix).\(ext)")

        switch conflictResolution {
        case .overwrite:
            return standard

        case .failWithConflict:
            reservationLock.lock()
            let isReserved = reservedDestinationPaths.contains(standard.path)
            reservationLock.unlock()
            if isReserved || fileManager.fileExists(atPath: standard.path) {
                throw ShiftKitError.outputConflict(standard)
            }
            reservationLock.lock()
            reservedDestinationPaths.insert(standard.path)
            reservationLock.unlock()
            return standard

        case .renameWithNumber:
            reservationLock.lock()
            defer { reservationLock.unlock() }
            var candidate = standard
            var counter = 1
            while fileManager.fileExists(atPath: candidate.path) || reservedDestinationPaths.contains(candidate.path) || candidate.standardizedFileURL.path == sourceURL.standardizedFileURL.path {
                candidate = targetDir.appendingPathComponent("\(baseWithSuffix)_\(counter).\(ext)")
                counter += 1
            }
            reservedDestinationPaths.insert(candidate.path)
            return candidate
        }
    }

    @MainActor
    private func promptUserForSaveLocation(
        sourceURL: URL,
        targetExtension: String?,
        suffix: String?
    ) async throws -> URL {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = (targetExtension ?? sourceURL.pathExtension).lowercased()
        let suggestedName: String
        if let suffix, !suffix.isEmpty {
            suggestedName = "\(baseName)_\(suffix).\(ext)"
        } else {
            suggestedName = "\(baseName).\(ext)"
        }

        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = suggestedName
        savePanel.directoryURL = sourceURL.deletingLastPathComponent()

        let response = savePanel.runModal()
        guard response == .OK, let selectedURL = savePanel.url else {
            throw ShiftKitError.cancelled
        }

        return selectedURL
    }
}
