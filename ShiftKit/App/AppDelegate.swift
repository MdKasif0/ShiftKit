import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Enforce Aqua (Light) appearance across all native AppKit windows
        NSApp.appearance = NSAppearance(named: .aqua)

        for window in NSApp.windows {
            configureWindowAppearance(window)
        }
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }

    public func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        NotificationCenter.default.post(
            name: NSNotification.Name("ShiftKitOpenFilesNotification"),
            object: urls
        )
    }

    private func configureWindowAppearance(_ window: NSWindow) {
        window.appearance = NSAppearance(named: .aqua)
        window.backgroundColor = ShiftKitColors.NS.warmIvory
        window.titlebarAppearsTransparent = false
    }
}
