import SwiftUI
import AppKit

@main
struct ShiftKitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup("ShiftKit") {
            MainView(coordinator: coordinator)
                .preferredColorScheme(.light)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 620, height: 740)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About ShiftKit") {
                    NSApp.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "ShiftKit",
                            .version: "1.0",
                            .credits: NSAttributedString(string: "Local-first radial file action utility for macOS.\nZero cloud uploads. 100% on-device.")
                        ]
                    )
                }

                Button("Check for Updates...") {
                    coordinator.updateManager.checkForUpdates()
                }
            }

            CommandGroup(after: .appSettings) {
                Button("Preferences...") {
                    coordinator.isSettingsPresented = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
