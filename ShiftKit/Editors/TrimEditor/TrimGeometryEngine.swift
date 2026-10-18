import Foundation
import CoreGraphics

// MARK: - Trim Geometry Engine
public struct TrimGeometryEngine: Sendable {
    public let totalDuration: Double
    public let minDuration: Double

    public init(totalDuration: Double, minDuration: Double = 0.25) {
        self.totalDuration = max(0.1, totalDuration)
        self.minDuration = min(minDuration, max(0.05, totalDuration / 2.0))
    }

    /// Converts a normalized ratio (0.0 ... 1.0) to timestamp in seconds.
    public func time(forRatio ratio: Double) -> Double {
        let clampedRatio = min(1.0, max(0.0, ratio))
        return clampedRatio * totalDuration
    }

    /// Converts a timestamp in seconds to a normalized ratio (0.0 ... 1.0).
    public func ratio(forTime time: Double) -> Double {
        guard totalDuration > 0 else { return 0.0 }
        let clampedTime = min(totalDuration, max(0.0, time))
        return clampedTime / totalDuration
    }

    /// Converts an X coordinate within a given timeline track width to a timestamp in seconds.
    public func time(forX x: CGFloat, inWidth width: CGFloat) -> Double {
        guard width > 0 else { return 0.0 }
        let ratio = Double(x / width)
        return time(forRatio: ratio)
    }

    /// Converts a timestamp in seconds to an X coordinate on a timeline of the given width.
    public func x(forTime time: Double, inWidth width: CGFloat) -> CGFloat {
        let r = ratio(forTime: time)
        return CGFloat(r) * width
    }

    /// Clamps and validates a proposed start and end time range.
    public func clampRange(start: Double, end: Double) -> (start: Double, end: Double) {
        var s = max(0.0, min(start, totalDuration - minDuration))
        var e = min(totalDuration, max(end, s + minDuration))

        if e - s < minDuration {
            if s + minDuration <= totalDuration {
                e = s + minDuration
            } else {
                s = max(0.0, e - minDuration)
            }
        }
        return (s, e)
    }

    /// Adjusts start time while keeping end time valid and enforcing minDuration.
    public func adjustStartTime(_ newStart: Double, currentEnd: Double) -> Double {
        let maxStart = max(0.0, currentEnd - minDuration)
        return max(0.0, min(newStart, maxStart))
    }

    /// Adjusts end time while keeping start time valid and enforcing minDuration.
    public func adjustEndTime(_ newEnd: Double, currentStart: Double) -> Double {
        let minEnd = min(totalDuration, currentStart + minDuration)
        return min(totalDuration, max(newEnd, minEnd))
    }

    /// Formats a time in seconds to mm:ss.ms (e.g. 01:23.45).
    public static func formatTimestamp(_ seconds: Double) -> String {
        guard seconds.isFinite && !seconds.isNaN else { return "00:00.00" }
        let positive = max(0.0, seconds)
        let totalInt = Int(positive)
        let mins = totalInt / 60
        let secs = totalInt % 60
        let hundredths = Int((positive.truncatingRemainder(dividingBy: 1.0)) * 100)
        return String(format: "%02d:%02d.%02d", mins, secs, hundredths)
    }
}
