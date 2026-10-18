import Foundation

// MARK: - Option Descriptors
public struct ConversionOptionDescriptor: Hashable, Sendable, Codable {
    public let key: String
    public let title: String
    public let detail: String
    public let defaultValue: String

    public init(key: String, title: String, detail: String, defaultValue: String) {
        self.key = key
        self.title = title
        self.detail = detail
        self.defaultValue = defaultValue
    }
}

// MARK: - Conversion Capability
/// Complete specification of a transformation capability between file formats and engines.
public struct ConversionCapability: Identifiable, Hashable, Sendable, Codable {
    public let id: String
    public let displayName: String
    public let category: FileCategory
    public let actionCategory: ActionCategory
    public let sourceFormatID: String
    public let targetFormatID: String
    public let requiredEngineID: String
    public let requiredCodecs: [String]
    public let supportedOptionKeys: [String]
    public let knownLimitations: [String]
    public let isLossless: Bool
    public let requiresIntermediateConversion: Bool
    public let intermediateFormatID: String?
    public let isImplemented: Bool

    public init(
        id: String,
        displayName: String,
        category: FileCategory,
        actionCategory: ActionCategory = .convert,
        sourceFormatID: String,
        targetFormatID: String,
        requiredEngineID: String,
        requiredCodecs: [String] = [],
        supportedOptionKeys: [String] = [],
        knownLimitations: [String] = [],
        isLossless: Bool = false,
        requiresIntermediateConversion: Bool = false,
        intermediateFormatID: String? = nil,
        isImplemented: Bool = true
    ) {
        self.id = id
        self.displayName = displayName
        self.category = category
        self.actionCategory = actionCategory
        self.sourceFormatID = sourceFormatID
        self.targetFormatID = targetFormatID
        self.requiredEngineID = requiredEngineID
        self.requiredCodecs = requiredCodecs
        self.supportedOptionKeys = supportedOptionKeys
        self.knownLimitations = knownLimitations
        self.isLossless = isLossless
        self.requiresIntermediateConversion = requiresIntermediateConversion
        self.intermediateFormatID = intermediateFormatID
        self.isImplemented = isImplemented
    }

    public var sourceFormat: OutputFormat? {
        OutputFormat.find(byExtension: sourceFormatID) ?? OutputFormat.allCanonical.first { $0.id == sourceFormatID }
    }

    public var targetFormat: OutputFormat? {
        OutputFormat.find(byExtension: targetFormatID) ?? OutputFormat.allCanonical.first { $0.id == targetFormatID }
    }

    public var intermediateFormat: OutputFormat? {
        guard let id = intermediateFormatID else { return nil }
        return OutputFormat.find(byExtension: id) ?? OutputFormat.allCanonical.first { $0.id == id }
    }
}
