import Foundation
import AppKit

// MARK: - Modifier Key Tracker
/// Tracks modifier key states (Shift, Option, Command, Control) locally and globally.
public final class ModifierKeyTracker: @unchecked Sendable {
    public static let shared = ModifierKeyTracker()

    public private(set) var isShiftPressed: Bool = false
    public private(set) var isOptionPressed: Bool = false
    public private(set) var isCommandPressed: Bool = false
    public private(set) var isControlPressed: Bool = false

    private var localFlagsMonitor: Any?
    private var globalFlagsMonitor: Any?
    private var stateChangeCallbacks: [(Bool) -> Void] = []
    private let lock = NSLock()

    private init() {
        startTracking()
    }

    public func onShiftStateChanged(_ callback: @escaping (Bool) -> Void) {
        lock.lock()
        stateChangeCallbacks.append(callback)
        lock.unlock()
    }

    public func startTracking() {
        // Monitor local flags changed (app in foreground)
        if localFlagsMonitor == nil {
            localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
                self?.handleFlagsChanged(event)
                return event
            }
        }

        // Monitor global flags changed (Finder or other apps in foreground)
        if globalFlagsMonitor == nil {
            globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
                self?.handleFlagsChanged(event)
            }
        }

        // Initialize current state from current modifier flags
        updateFromModifierFlags(NSEvent.modifierFlags)
    }

    public func stopTracking() {
        if let local = localFlagsMonitor {
            NSEvent.removeMonitor(local)
            localFlagsMonitor = nil
        }
        if let global = globalFlagsMonitor {
            NSEvent.removeMonitor(global)
            globalFlagsMonitor = nil
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        updateFromModifierFlags(event.modifierFlags)
    }

    private func updateFromModifierFlags(_ flags: NSEvent.ModifierFlags) {
        let shift = flags.contains(.shift)
        let option = flags.contains(.option)
        let command = flags.contains(.command)
        let control = flags.contains(.control)

        let shiftChanged = (shift != isShiftPressed)

        lock.lock()
        isShiftPressed = shift
        isOptionPressed = option
        isCommandPressed = command
        isControlPressed = control
        let callbacks = stateChangeCallbacks
        lock.unlock()

        if shiftChanged {
            DispatchQueue.main.async {
                for callback in callbacks {
                    callback(shift)
                }
            }
        }
    }

    deinit {
        stopTracking()
    }
}
