import Foundation
import CoreGraphics

// MARK: - Aspect Ratio Presets
public enum CropAspectRatioPreset: String, CaseIterable, Identifiable, Hashable, Sendable {
    case free = "Free"
    case square = "1:1"
    case landscape16_9 = "16:9"
    case portrait9_16 = "9:16"
    case landscape4_3 = "4:3"
    case portrait3_4 = "3:4"

    public var id: String { rawValue }

    public var ratio: Double? {
        switch self {
        case .free: return nil
        case .square: return 1.0
        case .landscape16_9: return 16.0 / 9.0
        case .portrait9_16: return 9.0 / 16.0
        case .landscape4_3: return 4.0 / 3.0
        case .portrait3_4: return 3.0 / 4.0
        }
    }
}

// MARK: - Crop Handle Types
public enum CropHandle: CaseIterable, Hashable, Sendable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case top
    case bottom
    case left
    case right
}

// MARK: - Crop Geometry Engine
/// Mathematical engine that computes clamped, ratio-preserving crop geometries and orientation transforms.
public struct CropGeometryEngine: Sendable {
    public let imageSize: CGSize
    public let minCropDimension: CGFloat

    public init(imageSize: CGSize, minCropDimension: CGFloat = 24.0) {
        self.imageSize = imageSize
        self.minCropDimension = minCropDimension
    }

    /// Computes the initial centered crop rectangle for a given aspect ratio preset.
    public func initialCropRect(for preset: CropAspectRatioPreset) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGRect(x: 0, y: 0, width: 100, height: 100)
        }

        guard let targetRatio = preset.ratio else {
            // Full image with a 5% margin for aesthetic framing
            let marginX = imageSize.width * 0.05
            let marginY = imageSize.height * 0.05
            return CGRect(
                x: marginX,
                y: marginY,
                width: max(imageSize.width - 2 * marginX, minCropDimension),
                height: max(imageSize.height - 2 * marginY, minCropDimension)
            )
        }

        let imageRatio = imageSize.width / imageSize.height
        let cropWidth: CGFloat
        let cropHeight: CGFloat

        if imageRatio > targetRatio {
            // Image is wider than target ratio: match height
            cropHeight = imageSize.height * 0.90
            cropWidth = cropHeight * CGFloat(targetRatio)
        } else {
            // Image is taller than target ratio: match width
            cropWidth = imageSize.width * 0.90
            cropHeight = cropWidth / CGFloat(targetRatio)
        }

        let originX = (imageSize.width - cropWidth) / 2.0
        let originY = (imageSize.height - cropHeight) / 2.0

        return clampToImageBounds(CGRect(x: originX, y: originY, width: cropWidth, height: cropHeight))
    }

    /// Moves the entire crop box by a delta (dx, dy), clamping inside the image bounds.
    public func moveCropRect(_ currentRect: CGRect, delta: CGPoint) -> CGRect {
        var newX = currentRect.origin.x + delta.x
        var newY = currentRect.origin.y + delta.y

        newX = max(0, min(newX, imageSize.width - currentRect.width))
        newY = max(0, min(newY, imageSize.height - currentRect.height))

        return CGRect(x: newX, y: newY, width: currentRect.width, height: currentRect.height)
    }

    /// Resizes the crop rectangle from a specific handle, strictly preserving aspect ratio and image bounds.
    public func resizeCropRect(
        _ currentRect: CGRect,
        handle: CropHandle,
        delta: CGPoint,
        preset: CropAspectRatioPreset
    ) -> CGRect {
        var minX = currentRect.minX
        var minY = currentRect.minY
        var maxX = currentRect.maxX
        var maxY = currentRect.maxY

        let ratio = preset.ratio

        if let ratio = ratio {
            // Aspect ratio constrained resize
            return resizeWithAspectRatio(
                currentRect: currentRect,
                handle: handle,
                delta: delta,
                ratio: CGFloat(ratio)
            )
        }

        // Freeform resize
        switch handle {
        case .topLeft:
            minX = min(minX + delta.x, maxX - minCropDimension)
            minY = min(minY + delta.y, maxY - minCropDimension)
        case .topRight:
            maxX = max(maxX + delta.x, minX + minCropDimension)
            minY = min(minY + delta.y, maxY - minCropDimension)
        case .bottomLeft:
            minX = min(minX + delta.x, maxX - minCropDimension)
            maxY = max(maxY + delta.y, minY + minCropDimension)
        case .bottomRight:
            maxX = max(maxX + delta.x, minX + minCropDimension)
            maxY = max(maxY + delta.y, minY + minCropDimension)
        case .top:
            minY = min(minY + delta.y, maxY - minCropDimension)
        case .bottom:
            maxY = max(maxY + delta.y, minY + minCropDimension)
        case .left:
            minX = min(minX + delta.x, maxX - minCropDimension)
        case .right:
            maxX = max(maxX + delta.x, minX + minCropDimension)
        }

        let unconstrained = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        return clampToImageBounds(unconstrained)
    }

    /// Clamps a rectangle to ensure it stays strictly within [0, 0, imageWidth, imageHeight].
    public func clampToImageBounds(_ rect: CGRect) -> CGRect {
        let clampedX = max(0, min(rect.origin.x, imageSize.width - minCropDimension))
        let clampedY = max(0, min(rect.origin.y, imageSize.height - minCropDimension))
        let clampedW = max(minCropDimension, min(rect.width, imageSize.width - clampedX))
        let clampedH = max(minCropDimension, min(rect.height, imageSize.height - clampedY))

        return CGRect(x: clampedX, y: clampedY, width: clampedW, height: clampedH)
    }

    /// Helper for aspect-ratio locked resizing
    private func resizeWithAspectRatio(
        currentRect: CGRect,
        handle: CropHandle,
        delta: CGPoint,
        ratio: CGFloat
    ) -> CGRect {
        var newWidth: CGFloat
        var newHeight: CGFloat
        var newOriginX = currentRect.origin.x
        var newOriginY = currentRect.origin.y

        switch handle {
        case .bottomRight:
            let deltaW = delta.x
            let deltaH = delta.y
            // Choose the dominant movement
            if abs(deltaW) > abs(deltaH) {
                newWidth = max(minCropDimension, currentRect.width + deltaW)
                newHeight = newWidth / ratio
            } else {
                newHeight = max(minCropDimension, currentRect.height + deltaH)
                newWidth = newHeight * ratio
            }

        case .bottomLeft:
            let deltaW = -delta.x
            let deltaH = delta.y
            if abs(deltaW) > abs(deltaH) {
                newWidth = max(minCropDimension, currentRect.width + deltaW)
                newHeight = newWidth / ratio
            } else {
                newHeight = max(minCropDimension, currentRect.height + deltaH)
                newWidth = newHeight * ratio
            }
            newOriginX = currentRect.maxX - newWidth

        case .topRight:
            let deltaW = delta.x
            let deltaH = -delta.y
            if abs(deltaW) > abs(deltaH) {
                newWidth = max(minCropDimension, currentRect.width + deltaW)
                newHeight = newWidth / ratio
            } else {
                newHeight = max(minCropDimension, currentRect.height + deltaH)
                newWidth = newHeight * ratio
            }
            newOriginY = currentRect.maxY - newHeight

        case .topLeft:
            let deltaW = -delta.x
            let deltaH = -delta.y
            if abs(deltaW) > abs(deltaH) {
                newWidth = max(minCropDimension, currentRect.width + deltaW)
                newHeight = newWidth / ratio
            } else {
                newHeight = max(minCropDimension, currentRect.height + deltaH)
                newWidth = newHeight * ratio
            }
            newOriginX = currentRect.maxX - newWidth
            newOriginY = currentRect.maxY - newHeight

        case .right, .left:
            let factor: CGFloat = (handle == .right) ? 1.0 : -1.0
            newWidth = max(minCropDimension, currentRect.width + delta.x * factor)
            newHeight = newWidth / ratio
            if handle == .left { newOriginX = currentRect.maxX - newWidth }
            newOriginY = currentRect.midY - (newHeight / 2.0)

        case .bottom, .top:
            let factor: CGFloat = (handle == .bottom) ? 1.0 : -1.0
            newHeight = max(minCropDimension, currentRect.height + delta.y * factor)
            newWidth = newHeight * ratio
            if handle == .top { newOriginY = currentRect.maxY - newHeight }
            newOriginX = currentRect.midX - (newWidth / 2.0)
        }

        // Clamp width and height to fit inside image bounds
        if newOriginX < 0 {
            newOriginX = 0
            if newWidth > imageSize.width {
                newWidth = imageSize.width
                newHeight = newWidth / ratio
            }
        }
        if newOriginX + newWidth > imageSize.width {
            newWidth = imageSize.width - newOriginX
            newHeight = newWidth / ratio
        }
        if newOriginY < 0 {
            newOriginY = 0
            if newHeight > imageSize.height {
                newHeight = imageSize.height
                newWidth = newHeight * ratio
            }
        }
        if newOriginY + newHeight > imageSize.height {
            newHeight = imageSize.height - newOriginY
            newWidth = newHeight * ratio
        }

        return CGRect(
            x: max(0, newOriginX),
            y: max(0, newOriginY),
            width: max(minCropDimension, newWidth),
            height: max(minCropDimension, newHeight)
        )
    }

    /// Converts a pixel crop rectangle to normalized coordinates [0.0 ... 1.0].
    public func normalizeRect(_ pixelRect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        return CGRect(
            x: pixelRect.origin.x / imageSize.width,
            y: pixelRect.origin.y / imageSize.height,
            width: pixelRect.width / imageSize.width,
            height: pixelRect.height / imageSize.height
        )
    }

    /// Converts normalized coordinates [0.0 ... 1.0] back to image pixel coordinates.
    public func denormalizeRect(_ normRect: CGRect) -> CGRect {
        return CGRect(
            x: normRect.origin.x * imageSize.width,
            y: normRect.origin.y * imageSize.height,
            width: normRect.width * imageSize.width,
            height: normRect.height * imageSize.height
        )
    }
}
