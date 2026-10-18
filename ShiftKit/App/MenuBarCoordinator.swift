import AppKit

public final class MenuBarCoordinator: NSObject, @unchecked Sendable {
    private var statusItem: NSStatusItem?
    private weak var appCoordinator: AppCoordinator?

    public init(appCoordinator: AppCoordinator) {
        self.appCoordinator = appCoordinator
        super.init()
    }

    @MainActor
    public func setupStatusBarItem() {
        guard statusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "arrow.triangle.swap", accessibilityDescription: "ShiftKit Menu")
            button.image?.isTemplate = true
            button.toolTip = "ShiftKit: Local File Utility"
        }

        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "ShiftKit", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        let statusDesc = NSMenuItem(title: "Local Processing: Active", action: nil, keyEquivalent: "")
        statusDesc.isEnabled = false
        menu.addItem(statusDesc)

        menu.addItem(NSMenuItem.separator())

        let queueItem = NSMenuItem(title: "Activity & Queue...", action: #selector(openJobQueue), keyEquivalent: "j")
        queueItem.target = self
        menu.addItem(queueItem)

        let openMainItem = NSMenuItem(title: "Open Main Window", action: #selector(openMainWindow), keyEquivalent: "o")
        openMainItem.target = self
        menu.addItem(openMainItem)

        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "u")
        updateItem.target = self
        menu.addItem(updateItem)

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit ShiftKit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        item.menu = menu
        self.statusItem = item
    }

    @MainActor
    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title.contains("ShiftKit") }) {
            window.makeKeyAndOrderFront(nil)
        }
    }

    @MainActor
    @objc private func openJobQueue() {
        JobQueueWindowController.shared.present()
    }

    @MainActor
    @objc private func checkForUpdates() {
        appCoordinator?.updateManager.checkForUpdates()
    }

    @MainActor
    @objc private func openPreferences() {
        SettingsWindowController.shared.present()
    }
}
