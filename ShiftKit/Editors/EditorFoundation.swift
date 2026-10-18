import Foundation
import CoreGraphics

// MARK: - Editor Foundation Protocols
/// Foundation for dedicated visual crop, trim, and merge editors in upcoming steps.
public protocol MediaEditorPresenting: AnyObject, Sendable {
    func presentCropEditor(for file: InspectedFile, onComplete: @escaping (CropConfiguration) -> Void)
    func presentTrimEditor(for file: InspectedFile, onComplete: @escaping (TrimConfiguration) -> Void)
    func presentMergeEditor(for files: [InspectedFile], onComplete: @escaping (MergeConfiguration) -> Void)
}

public struct CropConfiguration: Hashable, Sendable {
    public var rect: CGRect
    public var aspectRatio: Double?
    public var maintainResolution: Bool

    public init(rect: CGRect = .zero, aspectRatio: Double? = nil, maintainResolution: Bool = true) {
        self.rect = rect
        self.aspectRatio = aspectRatio
        self.maintainResolution = maintainResolution
    }
}

public struct TrimConfiguration: Hashable, Sendable {
    public var startTimeSeconds: Double
    public var endTimeSeconds: Double

    public init(startTimeSeconds: Double = 0.0, endTimeSeconds: Double = 0.0) {
        self.startTimeSeconds = startTimeSeconds
        self.endTimeSeconds = endTimeSeconds
    }
}

public struct MergeConfiguration: Hashable, Sendable {
    public var fileURLs: [URL]
    public var destinationFormat: String

    public init(fileURLs: [URL] = [], destinationFormat: String = "pdf") {
        self.fileURLs = fileURLs
        self.destinationFormat = destinationFormat
    }
}
