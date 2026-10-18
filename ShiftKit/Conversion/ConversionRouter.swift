import Foundation

// MARK: - Protocol
public protocol ConversionRouting: Sendable {
    func route(request: ConversionRequest) throws -> ConversionEngine
    func resolveDestination(for request: ConversionRequest) -> URL
}

// MARK: - Implementation
public final class ConversionRouter: ConversionRouting {
    private let engines: [ConversionEngine]
    private let outputManager: OutputManaging

    public init(
        engines: [ConversionEngine] = [
            ImageIOCoreEngine(),
            PDFKitEngine(),
            AVFoundationEngine(),
            FFmpegEngine()
        ],
        outputManager: OutputManaging = OutputManager()
    ) {
        self.engines = engines
        self.outputManager = outputManager
    }

    public func route(request: ConversionRequest) throws -> ConversionEngine {
        // Find first matching engine that handles this action and file type
        for engine in engines {
            if engine.canHandle(action: request.action, fileType: request.fileType) {
                return engine
            }
        }

        throw ShiftKitError.unsupportedAction(request.action.title)
    }

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
}
