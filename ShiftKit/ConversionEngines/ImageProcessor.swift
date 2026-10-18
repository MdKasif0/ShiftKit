import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import AppKit

// MARK: - Image Processing Result
public struct ImageProcessingReport: Sendable {
    public let originalURL: URL
    public let outputURL: URL
    public let originalSizeBytes: Int64
    public let outputSizeBytes: Int64
    public let savingsBytes: Int64
    public let percentageChange: Double // e.g. -45.2%
    public let outputDimensions: CGSize
    public let isLossless: Bool
    public let strippedMetadata: Bool
    public let preservedAnimation: Bool

    public init(
        originalURL: URL,
        outputURL: URL,
        originalSizeBytes: Int64,
        outputSizeBytes: Int64,
        outputDimensions: CGSize,
        isLossless: Bool,
        strippedMetadata: Bool,
        preservedAnimation: Bool
    ) {
        self.originalURL = originalURL
        self.outputURL = outputURL
        self.originalSizeBytes = originalSizeBytes
        self.outputSizeBytes = outputSizeBytes
        self.savingsBytes = originalSizeBytes - outputSizeBytes
        if originalSizeBytes > 0 {
            self.percentageChange = Double(outputSizeBytes - originalSizeBytes) / Double(originalSizeBytes) * 100.0
        } else {
            self.percentageChange = 0.0
        }
        self.outputDimensions = outputDimensions
        self.isLossless = isLossless
        self.strippedMetadata = strippedMetadata
        self.preservedAnimation = preservedAnimation
    }

    public var formattedComparison: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file

        let originalStr = formatter.string(fromByteCount: originalSizeBytes)
        let outputStr = formatter.string(fromByteCount: outputSizeBytes)
        let sign = percentageChange > 0 ? "+" : ""
        let percentStr = String(format: "%@%.1f%%", sign, percentageChange)

        return "\(originalStr) → \(outputStr) (\(percentStr))"
    }
}

// MARK: - Image Processor
/// High-performance local-first image processing engine utilizing CoreGraphics, ImageIO, and packaged WebP tools.
public final class ImageProcessor: Sendable {
    public static let shared = ImageProcessor()

    private let outputManager: OutputManaging

    public init(outputManager: OutputManaging = OutputManager()) {
        self.outputManager = outputManager
    }

    // MARK: - Primary Processing Pipeline
    public func process(
        sourceURL: URL,
        targetURL: URL,
        targetFormat: OutputFormat,
        cropRect: CGRect? = nil,         // in true pixel coordinates
        options: ConversionOptions = .default,
        progressHandler: @Sendable @escaping (Double, String) -> Void = { _, _ in }
    ) async throws -> ImageProcessingReport {
        progressHandler(0.1, "Reading image source...")

        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw ShiftKitError.fileNotFound(sourceURL)
        }

        let originalSize = (try? FileManager.default.attributesOfItem(atPath: sourceURL.path)[.size] as? NSNumber)?.int64Value ?? 0

        guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
            throw ShiftKitError.conversionFailed(reason: "Cannot create ImageIO source from \(sourceURL.lastPathComponent)")
        }

        let frameCount = CGImageSourceGetCount(imageSource)
        let isAnimated = frameCount > 1
        let preservesAnimation = isAnimated && (targetFormat == .gif)

        progressHandler(0.25, "Decoding image stream...")

        // Read orientation metadata
        let sourceProperties = (CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]) ?? [:]
        let orientationRaw = (sourceProperties[kCGImagePropertyOrientation] as? UInt32) ?? 1
        let orientation = CGImagePropertyOrientation(rawValue: orientationRaw) ?? .up

        // Decode full frame
        guard let sourceImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to decode primary image frame")
        }

        progressHandler(0.45, "Applying transformations...")

        // 1. Apply visual orientation normalization
        let orientedImage = normalizeOrientation(image: sourceImage, orientation: orientation)

        // 2. Apply Crop if specified
        let croppedImage: CGImage
        if let cropRect = cropRect, cropRect.width > 0, cropRect.height > 0 {
            croppedImage = try applyCrop(image: orientedImage, cropRect: cropRect)
        } else {
            croppedImage = orientedImage
        }

        // 3. Apply Resize if specified
        let finalImage = applyResize(image: croppedImage, options: options)

        progressHandler(0.70, "Writing temporary output...")

        // 4. Create atomic temporary output destination
        let tempURL = try outputManager.createTemporaryOutputURL(for: targetURL)

        do {
            if targetFormat == .webp {
                // Encode WebP via packaged WebP engine
                try encodeWebP(
                    sourceImage: finalImage,
                    tempURL: tempURL,
                    options: options,
                    stripMetadata: options.stripMetadata
                )
            } else if targetFormat == .pdf {
                // Export Image to PDF Document
                try encodePDF(
                    image: finalImage,
                    tempURL: tempURL
                )
            } else {
                // Native ImageIO encoding (PNG, JPEG, HEIC, TIFF, BMP, GIF, AVIF)
                try encodeNative(
                    image: finalImage,
                    tempURL: tempURL,
                    targetFormat: targetFormat,
                    options: options,
                    sourceProperties: sourceProperties,
                    stripMetadata: options.stripMetadata
                )
            }

            // 5. Validate output file
            guard FileManager.default.fileExists(atPath: tempURL.path) else {
                throw ShiftKitError.conversionFailed(reason: "Output file was not generated by engine")
            }

            let outputAttributes = try FileManager.default.attributesOfItem(atPath: tempURL.path)
            let outputSize = (outputAttributes[.size] as? NSNumber)?.int64Value ?? 0
            guard outputSize > 0 else {
                throw ShiftKitError.conversionFailed(reason: "Generated image file has zero bytes")
            }

            progressHandler(0.95, "Finalizing output...")

            // 6. Atomically commit temp file
            try outputManager.commitTemporaryOutput(temporaryURL: tempURL, destinationURL: targetURL)

            progressHandler(1.0, "Complete")

            let finalDimensions = CGSize(width: finalImage.width, height: finalImage.height)
            let isLossless = !targetFormat.isContainerLossy && (options.isLosslessPreferred || targetFormat == .png || targetFormat == .tiff)

            return ImageProcessingReport(
                originalURL: sourceURL,
                outputURL: targetURL,
                originalSizeBytes: originalSize,
                outputSizeBytes: outputSize,
                outputDimensions: finalDimensions,
                isLossless: isLossless,
                strippedMetadata: options.stripMetadata,
                preservedAnimation: preservesAnimation
            )

        } catch {
            outputManager.cleanupTemporaryOutput(temporaryURL: tempURL)
            throw error
        }
    }

    // MARK: - Crop Operation
    public func applyCrop(image: CGImage, cropRect: CGRect) throws -> CGImage {
        let imgWidth = CGFloat(image.width)
        let imgHeight = CGFloat(image.height)

        let clampedX = max(0, min(cropRect.origin.x, imgWidth - 1))
        let clampedY = max(0, min(cropRect.origin.y, imgHeight - 1))
        let clampedW = max(1, min(cropRect.width, imgWidth - clampedX))
        let clampedH = max(1, min(cropRect.height, imgHeight - clampedY))

        let validRect = CGRect(x: clampedX, y: clampedY, width: clampedW, height: clampedH)

        guard let cropped = image.cropping(to: validRect) else {
            throw ShiftKitError.conversionFailed(reason: "CoreGraphics cropping operation failed for bounds \(validRect)")
        }

        return cropped
    }

    // MARK: - Resize Operation
    public func applyResize(image: CGImage, options: ConversionOptions) -> CGImage {
        let currentWidth = CGFloat(image.width)
        let currentHeight = CGFloat(image.height)
        var targetWidth = currentWidth
        var targetHeight = currentHeight

        // 1. Percentage scaling
        if let scale = options.scaleMultiplier, scale > 0 {
            targetWidth = round(currentWidth * CGFloat(scale))
            targetHeight = round(currentHeight * CGFloat(scale))
        }
        // 2. Explicit width & height
        else if let w = options.targetWidth, let h = options.targetHeight, w > 0, h > 0 {
            targetWidth = CGFloat(w)
            targetHeight = CGFloat(h)
        }
        // 3. Width-only
        else if let w = options.targetWidth, w > 0 {
            targetWidth = CGFloat(w)
            targetHeight = round(currentHeight * (targetWidth / currentWidth))
        }
        // 4. Height-only
        else if let h = options.targetHeight, h > 0 {
            targetHeight = CGFloat(h)
            targetWidth = round(currentWidth * (targetHeight / currentHeight))
        }
        // 5. Max dimension constraint (fit within)
        else if let maxDim = options.maxDimension, maxDim > 0 {
            let maxCurrent = max(currentWidth, currentHeight)
            if maxCurrent > CGFloat(maxDim) {
                let ratio = CGFloat(maxDim) / maxCurrent
                targetWidth = round(currentWidth * ratio)
                targetHeight = round(currentHeight * ratio)
            }
        }

        if Int(targetWidth) == image.width && Int(targetHeight) == image.height {
            return image
        }

        let wInt = max(1, Int(targetWidth))
        let hInt = max(1, Int(targetHeight))

        let colorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = image.bitmapInfo

        guard let context = CGContext(
            data: nil,
            width: wInt,
            height: hInt,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return image
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: wInt, height: hInt))

        return context.makeImage() ?? image
    }

    // MARK: - Native ImageIO Encoding
    private func encodeNative(
        image: CGImage,
        tempURL: URL,
        targetFormat: OutputFormat,
        options: ConversionOptions,
        sourceProperties: [CFString: Any],
        stripMetadata: Bool
    ) throws {
        let utType: UTType = {
            switch targetFormat.id {
            case "png": return .png
            case "jpeg", "jpg": return .jpeg
            case "heic": return .heic
            case "tiff", "tif": return .tiff
            case "bmp": return .bmp
            case "gif": return .gif
            case "avif": return UTType("public.avif") ?? .png
            default: return UTType(filenameExtension: targetFormat.primaryExtension) ?? .png
            }
        }()

        guard let destination = CGImageDestinationCreateWithURL(
            tempURL as CFURL,
            utType.identifier as CFString,
            1,
            nil
        ) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to initialize ImageIO destination for format \(targetFormat.displayName)")
        }

        var destOptions: [CFString: Any] = [:]

        // Quality setting for lossy formats
        if utType == .jpeg || utType == .heic || utType.identifier == "public.avif" {
            let quality = options.quality ?? 0.85
            destOptions[kCGImageDestinationLossyCompressionQuality] = quality
        }

        // Handle alpha flattening for formats that do not support transparency (e.g. JPEG)
        let finalImageToWrite: CGImage
        if !targetFormat.supportsAlpha && (image.alphaInfo == .first || image.alphaInfo == .last || image.alphaInfo == .premultipliedFirst || image.alphaInfo == .premultipliedLast) {
            finalImageToWrite = flattenAlpha(image: image, matteColorHex: options.matteColorHex) ?? image
        } else {
            finalImageToWrite = image
        }

        let propertiesDictionary: CFDictionary? = stripMetadata ? (destOptions as CFDictionary) : ({
            var merged = sourceProperties
            for (k, v) in destOptions { merged[k] = v }
            return merged as CFDictionary
        })()

        CGImageDestinationAddImage(destination, finalImageToWrite, propertiesDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to finalize ImageIO destination at \(tempURL.lastPathComponent)")
        }
    }

    // MARK: - WebP Encoding Pipeline
    private func encodeWebP(
        sourceImage: CGImage,
        tempURL: URL,
        options: ConversionOptions,
        stripMetadata: Bool
    ) throws {
        // 1. Write an intermediate PNG in temp location for cwebp consumption
        let tempPNG = tempURL.deletingPathExtension().appendingPathExtension("intermediate.png")
        defer { try? FileManager.default.removeItem(at: tempPNG) }

        guard let destination = CGImageDestinationCreateWithURL(tempPNG as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to initialize intermediate PNG for WebP encoding")
        }
        CGImageDestinationAddImage(destination, sourceImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to write intermediate PNG for WebP encoding")
        }

        // 2. Locate packaged cwebp binary
        guard let binaryURL = locateWebPBinary() else {
            throw ShiftKitError.engineNotAvailable(engineName: "Packaged cwebp binary missing from ShiftKit bundle")
        }

        var arguments: [String] = [tempPNG.path, "-o", tempURL.path]

        if options.isLosslessPreferred {
            arguments.append("-lossless")
        } else {
            let q = Int(round((options.quality ?? 0.82) * 100.0))
            arguments.append(contentsOf: ["-q", "\(max(1, min(100, q)))"])
        }

        if stripMetadata {
            arguments.append(contentsOf: ["-metadata", "none"])
        } else {
            arguments.append(contentsOf: ["-metadata", "all"])
        }

        let process = Process()
        process.executableURL = binaryURL
        process.arguments = arguments
        let pipe = Pipe()
        process.standardError = pipe
        process.standardOutput = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let err = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown"
            throw ShiftKitError.processExecutionFailed(exitCode: process.terminationStatus, message: err)
        }
    }

    // MARK: - PDF Image Export Pipeline
    private func encodePDF(image: CGImage, tempURL: URL) throws {
        let w = CGFloat(image.width)
        let h = CGFloat(image.height)
        var mediaBox = CGRect(x: 0, y: 0, width: w, height: h)

        guard let context = CGContext(tempURL as CFURL, mediaBox: &mediaBox, nil) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to initialize PDF graphics context")
        }

        context.beginPage(mediaBox: &mediaBox)
        context.draw(image, in: mediaBox)
        context.endPage()
        context.closePDF()
    }

    // MARK: - Private Helpers
    private func normalizeOrientation(image: CGImage, orientation: CGImagePropertyOrientation) -> CGImage {
        guard orientation != .up else { return image }

        let width = image.width
        let height = image.height

        var transform = CGAffineTransform.identity

        switch orientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: CGFloat(width), y: CGFloat(height)).rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: CGFloat(height), y: 0).rotated(by: .pi / 2.0)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: CGFloat(width)).rotated(by: -.pi / 2.0)
        default:
            break
        }

        if orientation == .upMirrored || orientation == .downMirrored {
            transform = transform.translatedBy(x: CGFloat(width), y: 0).scaledBy(x: -1, y: 1)
        } else if orientation == .leftMirrored || orientation == .rightMirrored {
            transform = transform.translatedBy(x: CGFloat(height), y: 0).scaledBy(x: -1, y: 1)
        }

        let isRotated = (orientation == .left || orientation == .leftMirrored || orientation == .right || orientation == .rightMirrored)
        let newWidth = isRotated ? height : width
        let newHeight = isRotated ? width : height

        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: image.bitmapInfo.rawValue
        ) else {
            return image
        }

        context.concatenate(transform)
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage() ?? image
    }

    private func flattenAlpha(image: CGImage, matteColorHex: String?) -> CGImage? {
        let width = image.width
        let height = image.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return nil
        }

        // Fill background matte (default white #FFFFFF)
        context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    private func locateWebPBinary() -> URL? {
        let fm = FileManager.default

        // 1. App Bundle Resource
        if let url = Bundle.main.url(forResource: "cwebp", withExtension: nil) {
            return url
        }
        if let url = Bundle.main.url(forResource: "cwebp", withExtension: nil, subdirectory: "bin") {
            return url
        }

        // 2. Project directory during development/testing
        let localPath = "ShiftKit/Resources/bin/cwebp"
        if fm.isExecutableFile(atPath: localPath) {
            return URL(fileURLWithPath: localPath)
        }

        // 3. Absolute path to project resources
        let absPath = FileManager.default.currentDirectoryPath + "/ShiftKit/Resources/bin/cwebp"
        if fm.isExecutableFile(atPath: absPath) {
            return URL(fileURLWithPath: absPath)
        }

        return nil
    }
}
