import Foundation
import AppKit

// MARK: - Shift Key Monitor
/// Tracks the state of the Shift modifier key locally and globally.
public final class ShiftKeyMonitor: @unchecked Sendable {
    public static let shared = ShiftKeyMonitor()

    public private(set) var isShiftPressed: Bool = false
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var observers: [(Bool) -> Void] = []
    private let lock = NSLock()

    private init() {
        startMonitoring()
    }

    public func addObserver(_ callback: @escaping (Bool) -> Void) {
        lock.lock()
        observers.append(callback)
        lock.unlock()
    }

    public func startMonitoring() {
        // Local flags changed monitor (active when app is focused)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }

        // Global flags changed monitor (active when user is in Finder or other apps)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let isShift = event.modifierFlags.contains(.shift)
        if isShift != isShiftPressed {
            isShiftPressed = isShift
            lock.lock()
            let callbacks = observers
            lock.unlock()
            DispatchQueue.main.async {
                for callback in callbacks {
                    callback(isShift)
                }
            }
        }
    }

    deinit {
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
    }
}
