import AppKit
import SwiftUI

public final class MetadataInspectorWindowController: NSObject, NSWindowDelegate {
    public static let shared = MetadataInspectorWindowController()

    private var window: NSWindow?
    private var completionHandler: ((InspectedFile, [String: String], Bool) -> Void)?

    private override init() {
        super.init()
    }

    @MainActor
    public func present(
        for file: InspectedFile,
        onApplyChanges: @escaping (InspectedFile, [String: String], Bool) -> Void
    ) {
        self.completionHandler = onApplyChanges

        if window != nil {
            window?.close()
            window = nil
        }

        let inspectorView = MetadataInspectorView(
            inspectedFile: file,
            onApplyChanges: { [weak self] inspected, options, isStrip in
                self?.handleApply(inspected: inspected, options: options, isStrip: isStrip)
            },
            onClose: { [weak self] in
                self?.dismiss()
            }
        )

        let hostingController = NSHostingController(rootView: inspectorView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "ShiftKit Metadata Inspector"
        newWindow.contentViewController = hostingController
        newWindow.isReleasedWhenClosed = false
        newWindow.center()
        newWindow.delegate = self

        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @MainActor
    public func dismiss() {
        window?.close()
        window = nil
        completionHandler = nil
    }

    @MainActor
    private func handleApply(inspected: InspectedFile, options: [String: String], isStrip: Bool) {
        let handler = self.completionHandler
        dismiss()
        handler?(inspected, options, isStrip)
    }

    public func windowWillClose(_ notification: Notification) {
        completionHandler = nil
        window = nil
    }
}
