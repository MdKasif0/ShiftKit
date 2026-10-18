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
            NSPasteboard.PasteboardType("public.file-url")
        ])
    }

    // MARK: - NSDraggingDestination Implementation
    override public func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard hasAcceptableFiles(sender: sender) else {
            return []
        }
        updateHoverTarget(sender: sender)
        return .copy
    }

    override public func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard hasAcceptableFiles(sender: sender) else {
            return []
        }
        updateHoverTarget(sender: sender)
        return .copy
    }

    override public func draggingExited(_ sender: NSDraggingInfo?) {
        onDragExited?()
    }

    override public func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
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
        let types = sender.draggingPasteboard.types ?? []
        return types.contains(.fileURL) || types.contains(.URL)
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
        guard let items = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return []
        }
        return items.filter { $0.isFileURL }
    }
}
