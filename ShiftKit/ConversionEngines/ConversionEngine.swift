import Foundation

// MARK: - Engine Protocol
public protocol ConversionEngine: Sendable {
    var engineID: String { get }
    var engineName: String { get }
    func canHandle(action: ConversionAction, fileType: FileType) -> Bool
    func execute(
        request: ConversionRequest,
        outputURL: URL,
        progressHandler: @Sendable @escaping (Double, String) -> Void
    ) async throws -> URL
}
