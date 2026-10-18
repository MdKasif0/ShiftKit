import Foundation
import CoreGraphics
import SwiftUI
import AppKit

// MARK: - Menu Geometry Definition
public struct MenuGeometry: Sendable, Hashable {
    public let innerRadius: CGFloat
    public let outerRadius: CGFloat
    public let centerHubRadius: CGFloat
    public let segmentCount: Int
    public let startAngleOffset: Double // Degrees (-90 = 12 o'clock)

    public init(
        innerRadius: CGFloat = 58,
        outerRadius: CGFloat = 158,
        centerHubRadius: CGFloat = 52,
        segmentCount: Int = 8,
        startAngleOffset: Double = -90.0
    ) {
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
        self.centerHubRadius = centerHubRadius
        self.segmentCount = max(segmentCount, 1)
        self.startAngleOffset = startAngleOffset
    }

    public var totalDiameter: CGFloat {
        (outerRadius + 16) * 2
    }
}

// MARK: - Hit Test Result
public enum RadialHitTestResult: Equatable, Sendable {
    case centerHub
    case segment(index: Int)
    case outside
}

// MARK: - Menu Layout Engine
public final class MenuLayoutEngine: Sendable {
    public static let shared = MenuLayoutEngine()

    public init() {}

    /// Calculates the angular range (start, end, mid) for a segment at a given index.
    public func angleRange(
        for segmentIndex: Int,
        geometry: MenuGeometry = MenuGeometry()
    ) -> (start: Angle, end: Angle, mid: Angle) {
        let count = Double(geometry.segmentCount)
        let sliceDegrees = 360.0 / count
        let startDeg = geometry.startAngleOffset + (Double(segmentIndex) * sliceDegrees)
        let endDeg = startDeg + sliceDegrees
        let midDeg = startDeg + (sliceDegrees / 2.0)

        return (
            start: Angle(degrees: startDeg),
            end: Angle(degrees: endDeg),
            mid: Angle(degrees: midDeg)
        )
    }

    /// Converts polar coordinates (radius, angle) relative to a center point into Cartesian CGPoint.
    public func pointOnCircle(
        radius: CGFloat,
        angle: Angle,
        center: CGPoint
    ) -> CGPoint {
        let x = center.x + (radius * CGFloat(cos(angle.radians)))
        let y = center.y + (radius * CGFloat(sin(angle.radians)))
        return CGPoint(x: x, y: y)
    }

    /// Hit-tests a point in the local coordinate space of the menu view.
    public func hitTest(
        point: CGPoint,
        in bounds: CGSize,
        geometry: MenuGeometry = MenuGeometry()
    ) -> RadialHitTestResult {
        let center = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = sqrt(dx * dx + dy * dy)

        // 1. Center hub hit
        if distance <= geometry.centerHubRadius {
            return .centerHub
        }

        // 2. Outside radial boundaries
        if distance < geometry.innerRadius || distance > (geometry.outerRadius + 8) {
            return .outside
        }

        // 3. Segment angular hit
        // Note: atan2(dy, dx) returns angle in radians [-pi, pi]
        var angleDegrees = Double(atan2(dy, dx)) * 180.0 / .pi

        // Normalize angle relative to startAngleOffset (-90 deg = 0)
        var normalizedAngle = angleDegrees - geometry.startAngleOffset
        while normalizedAngle < 0 {
            normalizedAngle += 360.0
        }
        while normalizedAngle >= 360.0 {
            normalizedAngle -= 360.0
        }

        let sliceDegrees = 360.0 / Double(geometry.segmentCount)
        let index = Int(normalizedAngle / sliceDegrees)
        let clampedIndex = min(max(index, 0), geometry.segmentCount - 1)

        return .segment(index: clampedIndex)
    }

    /// Positions a floating window centered on the target point, clamped within the screen's visible frame.
    public func clampedWindowOrigin(
        targetCenter: CGPoint,
        windowSize: CGSize,
        targetScreen: NSScreen? = nil
    ) -> CGPoint {
        // Find screen containing target center or fallback to main screen (safe against empty screens in headless/CI)
        guard let screen = targetScreen
            ?? NSScreen.screens.first(where: { $0.frame.contains(targetCenter) })
            ?? NSScreen.main
            ?? NSScreen.screens.first else {
            return CGPoint(x: targetCenter.x - windowSize.width / 2.0, y: targetCenter.y - windowSize.height / 2.0)
        }

        let visibleFrame = screen.visibleFrame
        let halfW = windowSize.width / 2.0
        let halfH = windowSize.height / 2.0

        var originX = targetCenter.x - halfW
        var originY = targetCenter.y - halfH

        // Clamp horizontally within screen
        if originX < visibleFrame.minX {
            originX = visibleFrame.minX + 8
        } else if originX + windowSize.width > visibleFrame.maxX {
            originX = visibleFrame.maxX - windowSize.width - 8
        }

        // Clamp vertically within screen
        if originY < visibleFrame.minY {
            originY = visibleFrame.minY + 8
        } else if originY + windowSize.height > visibleFrame.maxY {
            originY = visibleFrame.maxY - windowSize.height - 8
        }

        return CGPoint(x: originX, y: originY)
    }
}
