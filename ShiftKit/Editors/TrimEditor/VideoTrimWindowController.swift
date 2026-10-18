import AppKit
import SwiftUI

// MARK: - Video Trim Window Controller
@MainActor
public final class VideoTrimWindowController: NSObject, NSWindowDelegate {
    public static let shared = VideoTrimWindowController()

    private var window: NSWindow?
    private var onApplyCallback: ((Double, Double, ConversionOptions, OutputFormat) -> Void)?
    private var onCancelCallback: (() -> Void)?

    private override init() {
        super.init()
    }

    /// Presents the native video trim editor window for an inspected file.
    public func present(
        for file: InspectedFile,
        onApply: @escaping (Double, Double, ConversionOptions, OutputFormat) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.onApplyCallback = onApply
        self.onCancelCallback = onCancel

        if let existing = window {
            existing.close()
        }

        let editorView = VideoTrimEditorView(
            file: file,
            onApply: { [weak self] start, end, options, targetFormat in
                self?.window?.close()
                self?.onApplyCallback?(start, end, options, targetFormat)
            },
            onCancel: { [weak self] in
                self?.window?.close()
                self?.onCancelCallback?()
            }
        )

        let hostingController = NSHostingController(rootView: editorView)
        let initialRect = NSRect(x: 0, y: 0, width: 920, height: 680)

        let newWindow = NSWindow(
            contentRect: initialRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        newWindow.title = "Trim & Adjust Video — \(file.fileName)"
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
