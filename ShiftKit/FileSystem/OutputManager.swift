import Foundation
import AppKit

// MARK: - Protocol
public protocol OutputManaging: Sendable {
    func defaultOutputDirectory() -> URL
    func resolveDestinationURL(
        for sourceURL: URL,
        targetExtension: String?,
        suffix: String?,
        customDirectory: URL?
    ) -> URL
    func revealInFinder(url: URL)
    func openFile(url: URL)
}

// MARK: - Implementation
public final class OutputManager: OutputManaging {
    private let fileManager = FileManager.default

    public init() {}

    public func defaultOutputDirectory() -> URL {
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

        // Ensure directory exists
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

        var candidate = targetDir.appendingPathComponent("\(baseWithSuffix).\(ext)")
        var counter = 1

        // Resolve name collisions safely
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = targetDir.appendingPathComponent("\(baseWithSuffix)_\(counter).\(ext)")
            counter += 1
        }

        return candidate
    }

    @MainActor
    public func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    @MainActor
    public func openFile(url: URL) {
        NSWorkspace.shared.open(url)
    }
}
