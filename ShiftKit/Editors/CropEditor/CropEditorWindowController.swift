import AppKit
import SwiftUI

// MARK: - Crop Editor Window Controller
@MainActor
public final class CropEditorWindowController: NSObject, NSWindowDelegate {
    public static let shared = CropEditorWindowController()

    private var window: NSWindow?
    private var onApplyCallback: ((CGRect, ConversionOptions, OutputFormat) -> Void)?
    private var onCancelCallback: (() -> Void)?

    private override init() {
        super.init()
    }

    /// Presents the native crop editor window for an inspected file.
    public func present(
        for file: InspectedFile,
        onApply: @escaping (CGRect, ConversionOptions, OutputFormat) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.onApplyCallback = onApply
        self.onCancelCallback = onCancel

        if let existing = window {
            existing.close()
        }

        let editorView = CropEditorView(
            file: file,
            onApply: { [weak self] cropRect, options, targetFormat in
                self?.window?.close()
                self?.onApplyCallback?(cropRect, options, targetFormat)
            },
            onCancel: { [weak self] in
                self?.window?.close()
                self?.onCancelCallback?()
            }
        )

        let hostingController = NSHostingController(rootView: editorView)
        let initialRect = NSRect(x: 0, y: 0, width: 880, height: 660)

        let newWindow = NSWindow(
            contentRect: initialRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        newWindow.title = "Crop & Adjust — \(file.fileName)"
        newWindow.backgroundColor = ShiftKitColors.NS.warmIvory
        newWindow.contentViewController = hostingController
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self

        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func close() {
        window?.close()
        window = nil
    }

    public func windowWillClose(_ notification: Notification) {
        self.window = nil
    }
}
