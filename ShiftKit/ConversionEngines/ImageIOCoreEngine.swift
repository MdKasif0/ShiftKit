import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public final class ImageIOCoreEngine: ConversionEngine {
    public let engineID = "com.shiftkit.engine.imageio"
    public let engineName = "ImageIO & CoreGraphics"

    public init() {}

    public func canHandle(action: ConversionAction, fileType: FileType) -> Bool {
        guard case .image = fileType else { return false }
        switch action.category {
        case .convert, .compress, .cropOrTrim, .metadata, .edit:
            return true
        default:
            return false
        }
    }

    public func execute(
        request: ConversionRequest,
        outputURL: URL,
        progressHandler: @Sendable @escaping (Double, String) -> Void
    ) async throws -> URL {
        let targetExt = request.action.targetFormat?.lowercased() ?? outputURL.pathExtension.lowercased()
        let targetFormat = OutputFormat.find(byExtension: targetExt) ?? .png

        // Parse crop rectangle if passed in options or request
        let cropRect: CGRect? = {
            if let rectStr = request.options["cropRect"] {
                return NSRectFromString(rectStr)
            }
            if request.action.id == "img_crop_square" {
                // Read image dimensions to center a square
                if let source = CGImageSourceCreateWithURL(request.sourceURL as CFURL, nil),
                   let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                   let w = props[kCGImagePropertyPixelWidth] as? Int,
                   let h = props[kCGImagePropertyPixelHeight] as? Int {
                    let side = CGFloat(min(w, h))
                    let x = (CGFloat(w) - side) / 2.0
                    let y = (CGFloat(h) - side) / 2.0
                    return CGRect(x: x, y: y, width: side, height: side)
                }
            }
            return nil
        }()

        var convOptions = request.conversionOptions
        if request.action.id == "img_strip_exif" {
            convOptions.stripMetadata = true
        }

        let report = try await ImageProcessor.shared.process(
            sourceURL: request.sourceURL,
            targetURL: outputURL,
            targetFormat: targetFormat,
            cropRect: cropRect,
            options: convOptions,
            progressHandler: progressHandler
        )

        return report.outputURL
    }
}
