import Foundation

// MARK: - Conversion Request
public struct ConversionRequest: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let sourceURL: URL
    public let fileType: FileType
    public let action: ConversionAction
    public let destinationURL: URL?
    public let options: [String: String]
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        sourceURL: URL,
        fileType: FileType,
        action: ConversionAction,
        destinationURL: URL? = nil,
        options: [String: String] = [:],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.fileType = fileType
        self.action = action
        self.destinationURL = destinationURL
        self.options = options
        self.timestamp = timestamp
    }
}
