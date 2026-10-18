import AppKit
import SwiftUI

public final class SettingsWindowController: NSWindowController {
    public static let shared = SettingsWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 660, height: 540),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ShiftKit Preferences"
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("ShiftKitSettingsWindow")

        super.init(window: window)

        let settingsView = SettingsView(settings: SettingsStore.shared)
        window.contentView = NSHostingView(rootView: settingsView)
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
