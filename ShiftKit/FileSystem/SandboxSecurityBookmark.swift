import Foundation

/// Manages security-scoped bookmarks for user-selected output folders.
public final class SandboxSecurityBookmark: @unchecked Sendable {
    public static let shared = SandboxSecurityBookmark()

    private init() {}

    public func createBookmark(for url: URL) -> Data? {
        do {
            return try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            return nil
        }
    }

    public func resolveBookmark(data: Data) -> URL? {
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            _ = url.startAccessingSecurityScopedResource()
            return url
        } catch {
            return nil
        }
    }
}
