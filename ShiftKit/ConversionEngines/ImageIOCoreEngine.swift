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
        case .convert, .compress, .crop, .utility:
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
        progressHandler(0.1, "Reading image source...")

        guard let imageSource = CGImageSourceCreateWithURL(request.sourceURL as CFURL, nil) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to create ImageIO source from URL.")
        }

        progressHandler(0.3, "Decoding image...")

        guard let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to decode image frame.")
        }

        // Determine destination UTI
        let targetFormat = request.action.targetFormat?.lowercased() ?? outputURL.pathExtension.lowercased()
        let destinationUTType: UTType = {
            switch targetFormat {
            case "png": return .png
            case "jpg", "jpeg": return .jpeg
            case "webp": return UTType("org.webmproject.webp") ?? .jpeg
            case "tiff", "tif": return .tiff
            case "heic": return .heic
            default: return .png
            }
        }()

        progressHandler(0.6, "Applying transformation...")

        // Process options (e.g. compression quality, strip metadata)
        var options: [CFString: Any] = [:]
        if let qualityStr = request.options["quality"] ?? request.action.options["quality"],
           let quality = Double(qualityStr) {
            options[kCGImageDestinationLossyCompressionQuality] = quality
        } else if destinationUTType == .jpeg {
            options[kCGImageDestinationLossyCompressionQuality] = 0.85
        }

        progressHandler(0.8, "Writing output file...")

        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            destinationUTType.identifier as CFString,
            1,
            nil
        ) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to create image destination at \(outputURL.path).")
        }

        // Strip metadata if requested, otherwise preserve orientation
        let imageProperties: CFDictionary? = (request.action.id == "img_strip_exif") ? nil : (options as CFDictionary)

        CGImageDestinationAddImage(destination, image, imageProperties)

        guard CGImageDestinationFinalize(destination) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to finalize and write image destination.")
        }

        progressHandler(1.0, "Completed")
        return outputURL
    }
}
