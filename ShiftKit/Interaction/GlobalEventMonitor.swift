import Foundation
import AppKit
import CoreGraphics

// MARK: - Global Event Monitor
/// Coordinates global passive event monitors and CGEventTap hooks.
/// Note: Passive global monitors cannot intercept other applications' drag sessions
/// or read private pasteboard data in-flight. They are used legitimately to detect
/// when the user holds Shift while dragging, allowing ShiftKit to present its floating
/// drop destination under the cursor.
public final class GlobalEventMonitor: @unchecked Sendable {
    public static let shared = GlobalEventMonitor()

    public private(set) var isMonitoring: Bool = false

    private var globalFlagsMonitor: Any?
    private var globalDragMonitor: Any?
    private var globalMouseUpMonitor: Any?
    private var globalKeyDownMonitor: Any?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    public var onShiftDragDetected: ((CGPoint) -> Void)?
    public var onDragEnded: (() -> Void)?
    public var onGlobalShortcutTriggered: (() -> Void)?

    private var isDragging: Bool = false
    private let lock = NSLock()

    private init() {}

    public func start() {
        guard !isMonitoring else { return }
        isMonitoring = true

        startPassiveMonitors()
        startEventTapIfPermitted()
    }

    public func stop() {
        guard isMonitoring else { return }
        isMonitoring = false

        stopPassiveMonitors()
        stopEventTap()
    }

    // MARK: - AppKit Passive Global Monitors
    private func startPassiveMonitors() {
        // 1. Modifier flags changed (Shift key detection)
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self else { return }
            let isShift = event.modifierFlags.contains(.shift)
            if isShift && self.isDragging {
                let loc = NSEvent.mouseLocation
                DispatchQueue.main.async {
                    self.onShiftDragDetected?(loc)
                }
            }
        }

        // 2. Mouse dragged (observed while moving items across apps)
        globalDragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            guard let self else { return }
            self.isDragging = true
            let isShift = event.modifierFlags.contains(.shift)
            if isShift {
                let loc = NSEvent.mouseLocation
                DispatchQueue.main.async {
                    self.onShiftDragDetected?(loc)
                }
            }
        }

        // 3. Mouse released (drag end detection)
        globalMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            guard let self else { return }
            if self.isDragging {
                self.isDragging = false
                DispatchQueue.main.async {
                    self.onDragEnded?()
                }
            }
        }

        // 4. Global fallback hotkey: Option + Shift + S (keyCode 1 = 's')
        globalKeyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains([.option, .shift]) && event.keyCode == 1 {
                DispatchQueue.main.async {
                    self.onGlobalShortcutTriggered?()
                }
            }
        }
    }

    private func stopPassiveMonitors() {
        if let m = globalFlagsMonitor { NSEvent.removeMonitor(m); globalFlagsMonitor = nil }
        if let m = globalDragMonitor { NSEvent.removeMonitor(m); globalDragMonitor = nil }
        if let m = globalMouseUpMonitor { NSEvent.removeMonitor(m); globalMouseUpMonitor = nil }
        if let m = globalKeyDownMonitor { NSEvent.removeMonitor(m); globalKeyDownMonitor = nil }
    }

    // MARK: - CGEvent.tapCreate for Low-Latency Event Tapping (Requires Accessibility)
    private func startEventTapIfPermitted() {
        guard InteractionPermissionManager.shared.isAccessibilityGranted else { return }

        let eventMask = (1 << CGEventType.leftMouseDragged.rawValue) |
                        (1 << CGEventType.flagsChanged.rawValue) |
                        (1 << CGEventType.leftMouseUp.rawValue)

        let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<GlobalEventMonitor>.fromOpaque(refcon).takeUnretainedValue()
                monitor.handleCGEvent(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: observer
        ) else {
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func stopEventTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let src = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
                self.runLoopSource = nil
            }
            self.eventTap = nil
        }
    }

    private func handleCGEvent(type: CGEventType, event: CGEvent) {
        switch type {
        case .leftMouseDragged:
            self.isDragging = true
            let flags = event.flags
            if flags.contains(.maskShift) {
                let loc = event.location
                let screenH = NSScreen.main?.frame.height ?? 1080
                let appKitPoint = CGPoint(x: loc.x, y: screenH - loc.y)
                DispatchQueue.main.async {
                    self.onShiftDragDetected?(appKitPoint)
                }
            }

        case .flagsChanged:
            let flags = event.flags
            if flags.contains(.maskShift) && self.isDragging {
                let loc = event.location
                let screenH = NSScreen.main?.frame.height ?? 1080
                let appKitPoint = CGPoint(x: loc.x, y: screenH - loc.y)
                DispatchQueue.main.async {
                    self.onShiftDragDetected?(appKitPoint)
                }
            }

        case .leftMouseUp:
            if self.isDragging {
                self.isDragging = false
                DispatchQueue.main.async {
                    self.onDragEnded?()
                }
            }

        default:
            break
        }
    }

    deinit {
        stop()
    }
}
