import Foundation
import AppKit

public protocol DragEventMonitoring: Sendable {
    func isAccessibilityGranted() -> Bool
    func requestAccessibilityPrompt()
}

public final class DragEventMonitor: DragEventMonitoring, @unchecked Sendable {
    public static let shared = DragEventMonitor()

    public init() {}

    public func isAccessibilityGranted() -> Bool {
        AXIsProcessTrusted()
    }

    public func requestAccessibilityPrompt() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
