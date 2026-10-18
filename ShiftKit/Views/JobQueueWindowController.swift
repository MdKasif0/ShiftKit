import AppKit
import SwiftUI

public final class JobQueueWindowController: NSWindowController {
    public static let shared = JobQueueWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 660, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ShiftKit Activity & History"
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("ShiftKitJobQueueWindow")
        window.minSize = NSSize(width: 580, height: 420)

        super.init(window: window)

        let studioView = JobQueueStudioView(jobManager: .shared, historyStore: .shared)
        window.contentView = NSHostingView(rootView: studioView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func present() {
        guard let window = self.window else { return }
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
