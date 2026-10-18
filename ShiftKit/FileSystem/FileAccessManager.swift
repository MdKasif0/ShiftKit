import Foundation
import UniformTypeIdentifiers

// MARK: - Validated File Model
public struct ValidatedFile: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let originalURL: URL
    public let resolvedURL: URL
    public let fileName: String
    public let fileSize: Int64
    public let contentType: UTType?
    public let isSymbolicLink: Bool
    public let isExternalVolume: Bool

    public init(
        id: UUID = UUID(),
        originalURL: URL,
        resolvedURL: URL,
        fileName: String,
        fileSize: Int64,
        contentType: UTType?,
        isSymbolicLink: Bool,
        isExternalVolume: Bool
    ) {
        self.id = id
        self.originalURL = originalURL
        self.resolvedURL = resolvedURL
        self.fileName = fileName
        self.fileSize = fileSize
        self.contentType = contentType
        self.isSymbolicLink = isSymbolicLink
        self.isExternalVolume = isExternalVolume
    }
}

// MARK: - File Access Error
public enum FileAccessError: LocalizedError, Hashable, Sendable {
    case emptySelection
    case fileNotFound(URL)
    case permissionDenied(URL)
    case unsafeExecutable(URL)
    case circularSymlink(URL)
    case directoryUnsupported(URL)

    public var errorDescription: String? {
        switch self {
        case .emptySelection:
            return "No files were provided for processing."
        case .fileNotFound(let url):
            return "File could not be found at path: \(url.path)"
        case .permissionDenied(let url):
            return "Permission denied reading file: \(url.lastPathComponent)"
        case .unsafeExecutable(let url):
            return "Execution of executable binaries is prohibited for security: \(url.lastPathComponent)"
        case .circularSymlink(let url):
            return "Circular or broken symbolic link encountered: \(url.lastPathComponent)"
        case .directoryUnsupported(let url):
            return "Directories cannot be converted directly: \(url.lastPathComponent)"
        }
    }
}

// MARK: - File Access Manager
public final class FileAccessManager: @unchecked Sendable {
    public static let shared = FileAccessManager()
    private let fileManager = FileManager.default

    public init() {}

    /// Validates and normalizes an incoming batch of URLs from drag-and-drop or file pickers.
    public func validateURLs(_ urls: [URL]) -> Result<[ValidatedFile], FileAccessError> {
        guard !urls.isEmpty else {
            return .failure(.emptySelection)
        }

        var validatedList: [ValidatedFile] = []

        for rawURL in urls {
            // 1. Ensure file URL scheme
            guard rawURL.isFileURL else {
                continue
            }

            // Standardize path (handles non-English, spaces, unicode)
            let standardized = rawURL.standardizedFileURL

            // 2. Check existence
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: standardized.path, isDirectory: &isDir) else {
                return .failure(.fileNotFound(rawURL))
            }

            // Reject folder drops as single file inputs
            if isDir.boolValue {
                return .failure(.directoryUnsupported(rawURL))
            }

            // 3. Check readability
            guard fileManager.isReadableFile(atPath: standardized.path) else {
                return .failure(.permissionDenied(rawURL))
            }

            // 4. Resolve symbolic links safely (checking for loops)
            let (resolvedURL, isSymlink) = resolveSymlinkSafely(standardized)
            guard let resolvedURL else {
                return .failure(.circularSymlink(rawURL))
            }

            // 5. Security: Never process macOS application bundles or Mach-O binaries as targets
            if resolvedURL.pathExtension.lowercased() == "app" {
                return .failure(.unsafeExecutable(rawURL))
            }

            // 6. Inspect metadata efficiently using URLResourceValues (no large file in-memory reads!)
            let resourceKeys: Set<URLResourceKey> = [.contentTypeKey, .fileSizeKey, .volumeIsLocalKey]
            let values = try? resolvedURL.resourceValues(forKeys: resourceKeys)

            let contentType = values?.contentType ?? UTType(filenameExtension: resolvedURL.pathExtension)
            let fileSize = Int64(values?.fileSize ?? 0)
            let isExternal = !(values?.volumeIsLocal ?? true) || resolvedURL.path.hasPrefix("/Volumes/")

            let file = ValidatedFile(
                originalURL: rawURL,
                resolvedURL: resolvedURL,
                fileName: rawURL.lastPathComponent,
                fileSize: fileSize,
                contentType: contentType,
                isSymbolicLink: isSymlink,
                isExternalVolume: isExternal
            )

            validatedList.append(file)
        }

        if validatedList.isEmpty {
            return .failure(.emptySelection)
        }

        return .success(validatedList)
    }

    /// Resolves symlinks safely with maximum hop limits to prevent circular loops
    private func resolveSymlinkSafely(_ url: URL) -> (resolved: URL?, isSymlink: Bool) {
        var current = url
        var hops = 0
        let maxHops = 10
        var isLink = false

        while hops < maxHops {
            let path = current.path
            guard let destination = try? fileManager.destinationOfSymbolicLink(atPath: path) else {
                // Not a symlink or terminal target reached
                return (current, isLink)
            }
            isLink = true
            hops += 1

            let nextURL: URL
            if destination.hasPrefix("/") {
                nextURL = URL(fileURLWithPath: destination)
            } else {
                nextURL = current.deletingLastPathComponent().appendingPathComponent(destination).standardizedFileURL
            }
            current = nextURL
        }

        // Exceeded max hops -> circular link
        return (nil, true)
    }
}
