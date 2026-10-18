import Foundation

// MARK: - Specific Conversion Warnings
public enum ConversionWarning: Hashable, Sendable, Codable {
    case alphaChannelDiscarded
    case lossyToLosslessContainer(source: String, target: String)
    case extensionMismatch(declared: String, actual: String)
    case animationStripped
    case audioDownsampled(details: String)
    case metadataStripped
    case largeResolutionWarning(dimensions: String)
    case custom(message: String)

    public var localizedDescription: String {
        switch self {
        case .alphaChannelDiscarded:
            return "Target format does not support transparency. The alpha channel will be flattened onto a neutral background."
        case .lossyToLosslessContainer(let src, let tgt):
            return "Converting from lossy \(src.uppercased()) to lossless \(tgt.uppercased()) will not restore previously discarded compression detail or fidelity."
        case .extensionMismatch(let decl, let actual):
            return "File extension .\(decl) differs from actual inspected container format (\(actual.uppercased())). Inspection corrected the input format."
        case .animationStripped:
            return "Target format is static. Animated sequence will be flattened to the primary keyframe."
        case .audioDownsampled(let details):
            return "Audio tracks will be downmixed or re-encoded (\(details))."
        case .metadataStripped:
            return "EXIF, GPS, and device metadata will be removed from the target file."
        case .largeResolutionWarning(let dim):
            return "High resolution input (\(dim)) may require significant memory and processing time."
        case .custom(let msg):
            return msg
        }
    }
}

// MARK: - Single Conversion Validation Result
public struct ConversionValidationResult: Hashable, Sendable {
    public let isValid: Bool
    public let capability: ConversionCapability?
    public let errorReason: String?
    public let warnings: [ConversionWarning]
    public let isLossless: Bool
    public let requiresIntermediateConversion: Bool
    public let intermediateFormat: OutputFormat?
    public let discardedFeatures: [String]
    public let suggestedOptions: ConversionOptions

    public init(
        isValid: Bool,
        capability: ConversionCapability? = nil,
        errorReason: String? = nil,
        warnings: [ConversionWarning] = [],
        isLossless: Bool = false,
        requiresIntermediateConversion: Bool = false,
        intermediateFormat: OutputFormat? = nil,
        discardedFeatures: [String] = [],
        suggestedOptions: ConversionOptions = .default
    ) {
        self.isValid = isValid
        self.capability = capability
        self.errorReason = errorReason
        self.warnings = warnings
        self.isLossless = isLossless
        self.requiresIntermediateConversion = requiresIntermediateConversion
        self.intermediateFormat = intermediateFormat
        self.discardedFeatures = discardedFeatures
        self.suggestedOptions = suggestedOptions
    }

    public static func valid(
        capability: ConversionCapability,
        warnings: [ConversionWarning] = [],
        isLossless: Bool = false,
        requiresIntermediate: Bool = false,
        intermediateFormat: OutputFormat? = nil,
        discardedFeatures: [String] = [],
        options: ConversionOptions = .default
    ) -> ConversionValidationResult {
        ConversionValidationResult(
            isValid: true,
            capability: capability,
            errorReason: nil,
            warnings: warnings,
            isLossless: isLossless,
            requiresIntermediateConversion: requiresIntermediate,
            intermediateFormat: intermediateFormat,
            discardedFeatures: discardedFeatures,
            suggestedOptions: options
        )
    }

    public static func invalid(reason: String) -> ConversionValidationResult {
        ConversionValidationResult(
            isValid: false,
            capability: nil,
            errorReason: reason,
            warnings: [],
            isLossless: false,
            requiresIntermediateConversion: false,
            intermediateFormat: nil,
            discardedFeatures: [],
            suggestedOptions: .default
        )
    }
}

// MARK: - Multi-File Batch Validation Result
public struct BatchValidationResult: Sendable {
    public let allCompatible: Bool
    public let targetFormat: OutputFormat
    public let fileResults: [URL: ConversionValidationResult]
    public let supportedFiles: [InspectedFile]
    public let unsupportedFiles: [(file: InspectedFile, reason: String)]
    public let outputNameConflicts: [URL: [URL]]
    public let generalWarnings: [ConversionWarning]

    public init(
        targetFormat: OutputFormat,
        fileResults: [URL: ConversionValidationResult],
        supportedFiles: [InspectedFile],
        unsupportedFiles: [(file: InspectedFile, reason: String)],
        outputNameConflicts: [URL: [URL]] = [:],
        generalWarnings: [ConversionWarning] = []
    ) {
        self.targetFormat = targetFormat
        self.fileResults = fileResults
        self.supportedFiles = supportedFiles
        self.unsupportedFiles = unsupportedFiles
        self.outputNameConflicts = outputNameConflicts
        self.generalWarnings = generalWarnings
        self.allCompatible = unsupportedFiles.isEmpty && outputNameConflicts.isEmpty
    }
}

// MARK: - Multi-File Merge Validation Result
public struct MergeValidationResult: Sendable {
    public let canMerge: Bool
    public let targetFormat: OutputFormat
    public let compatibleFiles: [InspectedFile]
    public let incompatibleFiles: [(file: InspectedFile, reason: String)]
    public let failureReason: String?

    public init(
        canMerge: Bool,
        targetFormat: OutputFormat,
        compatibleFiles: [InspectedFile],
        incompatibleFiles: [(file: InspectedFile, reason: String)],
        failureReason: String? = nil
    ) {
        self.canMerge = canMerge
        self.targetFormat = targetFormat
        self.compatibleFiles = compatibleFiles
        self.incompatibleFiles = incompatibleFiles
        self.failureReason = failureReason
    }
}
