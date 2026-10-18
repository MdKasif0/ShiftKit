import AppKit
import SwiftUI

// MARK: - Native Drop Destination View
/// An AppKit NSView that serves as a high-performance native drag-and-drop target,
/// tracking in-flight drags, calculating radial slice hits, and delivering file URLs.
public final class DropDestinationView: NSView {
    public var onDragUpdated: ((CGPoint, Int?) -> Void)?
    public var onDragExited: (() -> Void)?
    public var onFilesDropped: (([URL], Int?) -> Void)?

    private let layoutEngine = MenuLayoutEngine.shared
    private let geometry: MenuGeometry
    private var isDragActive: Bool = false

    override public var isFlipped: Bool {
        true
    }

    public init(frame: NSRect, geometry: MenuGeometry = MenuGeometry()) {
        self.geometry = geometry
        super.init(frame: frame)
        setupDraggingRegistration()
    }

    required init?(coder: NSCoder) {
        self.geometry = MenuGeometry()
        super.init(coder: coder)
        setupDraggingRegistration()
    }

    private func setupDraggingRegistration() {
        registerForDraggedTypes([
            .fileURL,
            .URL,
            NSPasteboard.PasteboardType("public.file-url"),
            NSPasteboard.PasteboardType("NSFilenamesPboardType"),
            NSPasteboard.PasteboardType("com.apple.finder.node")
        ])
    }

    override public func hitTest(_ point: NSPoint) -> NSView? {
        // When actively tracking a file drag, return self so DropDestinationView receives all dragging events.
        // During normal mouse clicks, hover, and gestures, return super.hitTest so hostingView (SwiftUI) receives all interactions!
        if isDragActive {
            return self
        }
        return super.hitTest(point)
    }

    // MARK: - NSDraggingDestination Implementation
    override public func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard hasAcceptableFiles(sender: sender) else {
            return []
        }
        isDragActive = true
        updateHoverTarget(sender: sender)
        return .copy
    }

    override public func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard hasAcceptableFiles(sender: sender) else {
            return []
        }
        isDragActive = true
        updateHoverTarget(sender: sender)
        return .copy
    }

    override public func draggingExited(_ sender: NSDraggingInfo?) {
        isDragActive = false
        onDragExited?()
    }

    override public func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isDragActive = false
        let urls = extractFileURLs(from: sender.draggingPasteboard)
        guard !urls.isEmpty else { return false }

        let localPoint = convert(sender.draggingLocation, from: nil)
        let hit = layoutEngine.hitTest(point: localPoint, in: bounds.size, geometry: geometry)

        let targetIndex: Int?
        if case .segment(let idx) = hit {
            targetIndex = idx
        } else {
            targetIndex = nil
        }

        onFilesDropped?(urls, targetIndex)
        return true
    }

    // MARK: - Helpers
    private func hasAcceptableFiles(sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        let types = pasteboard.types ?? []
        let acceptable: [NSPasteboard.PasteboardType] = [
            .fileURL,
            .URL,
            NSPasteboard.PasteboardType("public.file-url"),
            NSPasteboard.PasteboardType("NSFilenamesPboardType"),
            NSPasteboard.PasteboardType("com.apple.finder.node")
        ]
        if types.contains(where: { acceptable.contains($0) }) {
            return true
        }
        return pasteboard.canReadObject(forClasses: [NSURL.self], options: nil)
    }

    private func updateHoverTarget(sender: NSDraggingInfo) {
        let localPoint = convert(sender.draggingLocation, from: nil)
        let hit = layoutEngine.hitTest(point: localPoint, in: bounds.size, geometry: geometry)

        let targetIndex: Int?
        if case .segment(let idx) = hit {
            targetIndex = idx
        } else {
            targetIndex = nil
        }

        onDragUpdated?(localPoint, targetIndex)
    }

    private func extractFileURLs(from pasteboard: NSPasteboard) -> [URL] {
        var results: [URL] = []
        if let items = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            results.append(contentsOf: items.filter { $0.isFileURL })
        }
        if results.isEmpty, let filenames = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] {
            results.append(contentsOf: filenames.map { URL(fileURLWithPath: $0) })
        }
        if results.isEmpty, let str = pasteboard.string(forType: .fileURL), let url = URL(string: str), url.isFileURL {
            results.append(url)
        }
        return results
    }
}
