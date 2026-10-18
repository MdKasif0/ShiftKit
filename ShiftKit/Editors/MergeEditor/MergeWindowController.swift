import AppKit
import SwiftUI

public final class MergeWindowController: NSObject, NSWindowDelegate {
    public static let shared = MergeWindowController()

    private var window: NSWindow?
    private var completionHandler: (([URL], MergeWorkflowType, [String: String]) -> Void)?
    private var batchHandler: (([URL], OutputFormat, ConversionOptions) -> Void)?

    private override init() {
        super.init()
    }

    @MainActor
    public func present(
        for fileURLs: [URL],
        onBatchConvert: (([URL], OutputFormat, ConversionOptions) -> Void)? = nil,
        completion: @escaping ([URL], MergeWorkflowType, [String: String]) -> Void
    ) {
        self.completionHandler = completion
        self.batchHandler = onBatchConvert

        if window != nil {
            window?.close()
            window = nil
        }

        let editorView = MergeEditorView(
            initialURLs: fileURLs,
            onMerge: { [weak self] urls, workflow, options in
                self?.handleMerge(urls: urls, workflow: workflow, options: options)
            },
            onBatchConvert: { [weak self] urls, format, options in
                self?.handleBatchConvert(urls: urls, format: format, options: options)
            },
            onCancel: { [weak self] in
                self?.dismiss()
            }
        )

        let hostingController = NSHostingController(rootView: editorView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "ShiftKit Merge Studio"
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
        batchHandler = nil
    }

    @MainActor
    private func handleMerge(urls: [URL], workflow: MergeWorkflowType, options: [String: String]) {
        let handler = self.completionHandler
        dismiss()
        handler?(urls, workflow, options)
    }

    @MainActor
    private func handleBatchConvert(urls: [URL], format: OutputFormat, options: ConversionOptions) {
        let handler = self.batchHandler
        dismiss()
        handler?(urls, format, options)
    }

    public func windowWillClose(_ notification: Notification) {
        completionHandler = nil
        batchHandler = nil
        window = nil
    }
}
