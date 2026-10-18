import AppKit
import SwiftUI

// MARK: - Native Floating Radial Window (AppKit NSPanel)
public final class RadialMenuWindow: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating
        self.isMovableByWindowBackground = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.becomesKeyOnlyIfNeeded = true
        self.hidesOnDeactivate = false
    }

    override public var canBecomeKey: Bool {
        true
    }

    override public var canBecomeMain: Bool {
        false
    }
}

// MARK: - Radial Menu Window Controller
@MainActor
public final class RadialMenuWindowController: NSObject, @unchecked Sendable {
    public static let shared = RadialMenuWindowController()

    private var window: RadialMenuWindow?
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?
    private var keyMonitor: Any?

    private let menuSize = CGSize(width: 360, height: 360)

    private override init() {
        super.init()
    }

    /// Presents the radial action menu at a given screen coordinate (e.g. mouse cursor location).
    public func present(
        for file: InspectedFile,
        at screenPoint: CGPoint,
        onSelectAction: @escaping (ConversionAction) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        // Dismiss any existing presentation
        dismiss()

        // 1. Calculate clamped position across multiple displays
        let origin = MenuLayoutEngine.shared.clampedWindowOrigin(
            targetCenter: screenPoint,
            windowSize: menuSize
        )
        let frame = NSRect(origin: origin, size: menuSize)

        // 2. Build hosting view with RadialMenuView
        let radialView = RadialMenuView(
            file: file,
            onSelectAction: { [weak self] action in
                self?.dismiss()
                onSelectAction(action)
            },
            onDismiss: { [weak self] in
                self?.dismiss()
                onDismiss()
            }
        )

        let hostingView = NSHostingView(rootView: radialView)
        hostingView.frame = NSRect(origin: .zero, size: menuSize)

        // 3. Container view with integrated DropDestination overlay
        let containerView = NSView(frame: NSRect(origin: .zero, size: menuSize))
        containerView.addSubview(hostingView)

        let dropOverlay = DropDestinationView(frame: NSRect(origin: .zero, size: menuSize))
        dropOverlay.onFilesDropped = { [weak self] urls, targetIndex in
            self?.dismiss()
            DragSessionCoordinator.shared.handleDroppedURLs(urls, onSegmentIndex: targetIndex)
        }
        containerView.addSubview(dropOverlay)

        // 4. Initialize & configure panel
        let panel = RadialMenuWindow(contentRect: frame)
        panel.contentView = containerView
        panel.setFrame(frame, display: true)
        panel.alphaValue = 0.0

        self.window = panel

        // 5. Smooth fade-in
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 1.0
        }

        panel.makeKey()

        // 6. Install click-outside and key dismissal monitors
        installDismissalMonitors(panel: panel, onDismiss: onDismiss)
    }

    public func dismiss() {
        guard let panel = window else { return }

        removeDismissalMonitors()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            panel.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            self?.window = nil
        })
    }

    private func installDismissalMonitors(panel: NSPanel, onDismiss: @escaping () -> Void) {
        // Monitor clicks outside panel
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self, weak panel] event in
            guard let panel else { return event }
            let clickLocation = NSEvent.mouseLocation
            if !panel.frame.contains(clickLocation) {
                self?.dismiss()
                onDismiss()
            }
            return event
        }

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self, weak panel] event in
            guard let panel else { return }
            let clickLocation = NSEvent.mouseLocation
            if !panel.frame.contains(clickLocation) {
                DispatchQueue.main.async {
                    self?.dismiss()
                    onDismiss()
                }
            }
        }

        // Monitor Esc key locally
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Esc key
                self?.dismiss()
                onDismiss()
                return nil
            }
            return event
        }
    }

    private func removeDismissalMonitors() {
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }
}
