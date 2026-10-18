import Foundation
import AppKit

// MARK: - Permission Manager
/// Coordinates macOS Accessibility permissions required for global event tapping and drag detection.
public final class InteractionPermissionManager: @unchecked Sendable {
    public static let shared = InteractionPermissionManager()

    public private(set) var isAccessibilityGranted: Bool = false
    private var observers: [(Bool) -> Void] = []
    private var checkTimer: Timer?
    private let lock = NSLock()

    private init() {
        self.isAccessibilityGranted = AXIsProcessTrusted()
    }

    /// Checks if accessibility permission is currently trusted by the OS.
    @discardableResult
    public func checkPermission() -> Bool {
        let trusted = AXIsProcessTrusted()
        if trusted != isAccessibilityGranted {
            lock.lock()
            isAccessibilityGranted = trusted
            let callbacks = observers
            lock.unlock()

            DispatchQueue.main.async {
                for callback in callbacks {
                    callback(trusted)
                }
            }
        }
        return trusted
    }

    /// Requests system accessibility permissions prompt from the user.
    public func requestPermissionPrompt() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        startPollingForPermissionChange()
    }

    /// Opens macOS System Settings directly to Privacy & Security -> Accessibility.
    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        startPollingForPermissionChange()
    }

    /// Registers a callback to be notified when accessibility trust state changes.
    public func addObserver(_ callback: @escaping (Bool) -> Void) {
        lock.lock()
        observers.append(callback)
        lock.unlock()
    }

    /// Polls periodically after prompting until the user grants permission in System Settings.
    private func startPollingForPermissionChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.checkTimer == nil else { return }
            self.checkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self else { timer.invalidate(); return }
                if self.checkPermission() {
                    timer.invalidate()
                    self.checkTimer = nil
                }
            }
        }
    }

    // Explanatory texts for user presentation
    public var permissionExplanationTitle: String {
        "Accessibility Permission"
    }

    public var permissionExplanationDescription: String {
        "ShiftKit uses macOS Accessibility permissions solely to detect when you press Shift while dragging a file from Finder or your Desktop. Without this permission, you can still use ShiftKit via the global shortcut (⌥⇧S), the menu bar item, and the main drop target."
    }

    public var isPermissionOptional: Bool {
        true // The app remains 100% functional via shortcuts and direct drag-and-drop fallbacks
    }
}
