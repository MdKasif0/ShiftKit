import Foundation

// MARK: - Protocol
public protocol ConversionRouting: Sendable {
    func route(request: ConversionRequest) throws -> ConversionEngine
    func validate(request: ConversionRequest, inspectedFile: InspectedFile) -> ConversionValidationResult
    func validate(source: InspectedFile, targetFormat: OutputFormat, category: ActionCategory) -> ConversionValidationResult
    func resolveDestination(for request: ConversionRequest) -> URL
}

// MARK: - Implementation
public final class ConversionRouter: ConversionRouting {
    private let engines: [ConversionEngine]
    private let registry: ConversionRegistering
    private let outputManager: OutputManaging

    public init(
        engines: [ConversionEngine] = [
            ImageIOCoreEngine(),
            PDFKitEngine(),
            AVFoundationEngine(),
            FFmpegEngine(),
            DocumentConversionEngine()
        ],
        registry: ConversionRegistering = ConversionRegistry.shared,
        outputManager: OutputManaging = OutputManager()
    ) {
        self.engines = engines
        self.registry = registry
        self.outputManager = outputManager
    }

    /// Selects the appropriate processing engine for a given request.
    public func route(request: ConversionRequest) throws -> ConversionEngine {
        let sourceFormat = OutputFormat.find(byExtension: request.sourceURL.pathExtension) ?? .png
        let targetExt = request.action.targetFormat ?? request.sourceURL.pathExtension
        let targetFormat = OutputFormat.find(byExtension: targetExt) ?? sourceFormat

        if let cap = registry.capability(from: sourceFormat, to: targetFormat, category: request.action.category) {
            if let matched = engines.first(where: { $0.engineID == cap.requiredEngineID }) {
                return matched
            }
        }

        // Fallback: Find matching engine by action and file type
        for engine in engines {
            if engine.canHandle(action: request.action, fileType: request.fileType) {
                return engine
            }
        }

        throw ShiftKitError.unsupportedAction(request.action.title)
    }

    /// Deep validation of a conversion request against an inspected file, inspecting true container formats and feature losses.
    public func validate(request: ConversionRequest, inspectedFile: InspectedFile) -> ConversionValidationResult {
        let sourceFormat = inspectedFile.metadata.detectedFormat ?? mapFileTypeToFormat(request.fileType)
        let targetFormat = resolveTargetFormat(for: request.action, fallbackExtension: request.sourceURL.pathExtension)

        return validate(
            sourceFormat: sourceFormat,
            targetFormat: targetFormat,
            category: request.action.category,
            inspectedFile: inspectedFile
        )
    }

    /// Validates conversion between a source file and target format.
    public func validate(source: InspectedFile, targetFormat: OutputFormat, category: ActionCategory = .convert) -> ConversionValidationResult {
        let sourceFormat = source.metadata.detectedFormat ?? mapFileTypeToFormat(source.fileType)
        return validate(
            sourceFormat: sourceFormat,
            targetFormat: targetFormat,
            category: category,
            inspectedFile: source
        )
    }

    /// Resolves the destination URL with collision prevention and suffix handling.
    public func resolveDestination(for request: ConversionRequest) -> URL {
        if let explicit = request.destinationURL {
            return explicit
        }

        let ext = request.action.targetFormat ?? request.sourceURL.pathExtension
        let suffix = request.action.category.rawValue
        return outputManager.resolveDestinationURL(
            for: request.sourceURL,
            targetExtension: ext,
            suffix: suffix,
            customDirectory: nil
        )
    }

    // MARK: - Private Analysis & Validation
    private func validate(
        sourceFormat: OutputFormat,
        targetFormat: OutputFormat,
        category: ActionCategory,
        inspectedFile: InspectedFile
    ) -> ConversionValidationResult {
        // 1. Check capability in registry
        guard let capability = registry.capability(from: sourceFormat, to: targetFormat, category: category) else {
            return .invalid(reason: "No conversion capability registered between \(sourceFormat.displayName) and \(targetFormat.displayName).")
        }

        // 2. Reject unimplemented conversions (Never claim supported without working engine)
        guard capability.isImplemented else {
            return .invalid(reason: "\(capability.displayName) is currently planned and not yet implemented by any active engine.")
        }

        // 3. Find matching engine
        guard engines.contains(where: { $0.engineID == capability.requiredEngineID }) else {
            return .invalid(reason: "Required engine \(capability.requiredEngineID) is not registered or unavailable.")
        }

        var warnings: [ConversionWarning] = []
        var discardedFeatures: [String] = []

        // 4. Feature Loss: Alpha transparency
        if (inspectedFile.metadata.hasAlphaChannel || sourceFormat.supportsAlpha) && !targetFormat.supportsAlpha {
            warnings.append(.alphaChannelDiscarded)
            discardedFeatures.append("Alpha transparency (will be flattened onto neutral background)")
        }

        // 5. Container Fidelity: Lossy to Lossless
        // Never claim that converting a lossy file into a lossless container restores discarded information
        var isEffectivelyLossless = capability.isLossless
        if sourceFormat.isContainerLossy && !targetFormat.isContainerLossy {
            warnings.append(.lossyToLosslessContainer(source: sourceFormat.primaryExtension, target: targetFormat.primaryExtension))
            isEffectivelyLossless = false // Cannot claim losslessness when starting from lossy source
        }

        // 6. Extension Mismatch
        if inspectedFile.metadata.isFormatExtensionMismatch {
            warnings.append(.extensionMismatch(
                declared: inspectedFile.metadata.fileExtension,
                actual: sourceFormat.displayName
            ))
        }

        // 7. Intermediate Steps
        let requiresIntermediate = capability.requiresIntermediateConversion
        let intermediate = capability.intermediateFormat

        return ConversionValidationResult.valid(
            capability: capability,
            warnings: warnings,
            isLossless: isEffectivelyLossless,
            requiresIntermediate: requiresIntermediate,
            intermediateFormat: intermediate,
            discardedFeatures: discardedFeatures,
            options: .default
        )
    }

    private func resolveTargetFormat(for action: ConversionAction, fallbackExtension: String) -> OutputFormat {
        if let targetExt = action.targetFormat, let found = OutputFormat.find(byExtension: targetExt) {
            return found
        }
        return OutputFormat.find(byExtension: fallbackExtension) ?? .png
    }

    private func mapFileTypeToFormat(_ fileType: FileType) -> OutputFormat {
        switch fileType {
        case .image(let sub): return OutputFormat.find(byExtension: sub.rawValue) ?? .png
        case .video(let sub): return OutputFormat.find(byExtension: sub.rawValue) ?? .mp4
        case .audio(let sub): return OutputFormat.find(byExtension: sub.rawValue) ?? .wav
        case .pdf: return .pdf
        case .archive: return .zip
        case .document(let sub): return OutputFormat.find(byExtension: sub.rawValue) ?? .txt
        case .unknown(let ext): return OutputFormat.find(byExtension: ext) ?? .txt
        }
    }
}
