import Foundation
import SwiftUI
import Observation
import AppKit

@Observable
public final class RadialMenuCoordinator: @unchecked Sendable {
    public var isPresented: Bool = false
    public var currentFile: InspectedFile?
    public var availableSegments: [RadialSegmentItem] = []
    public var hoveredAction: ConversionAction?
    public var menuPosition: CGPoint = .zero
    public var isFloatingWindowActive: Bool = false

    private let registry: ConversionRegistering

    public init(registry: ConversionRegistering = ConversionRegistry.shared) {
        self.registry = registry
    }

    public func present(for file: InspectedFile, at position: CGPoint = .zero) {
        self.currentFile = file
        self.availableSegments = registry.segments(for: file)
        self.menuPosition = position
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            self.isPresented = true
        }
    }

    public func dismiss() {
        withAnimation(.easeOut(duration: 0.15)) {
            self.isPresented = false
            self.hoveredAction = nil
        }
    }

    @MainActor
    public func presentFloatingWindow(
        for file: InspectedFile,
        at screenPoint: CGPoint? = nil,
        onSelectAction: @escaping (ConversionAction) -> Void
    ) {
        let location = screenPoint ?? NSEvent.mouseLocation
        self.currentFile = file
        self.isFloatingWindowActive = true

        RadialMenuWindowController.shared.present(
            for: file,
            at: location,
            onSelectAction: { [weak self] action in
                self?.isFloatingWindowActive = false
                self?.dismiss()
                onSelectAction(action)
            },
            onDismiss: { [weak self] in
                self?.isFloatingWindowActive = false
                self?.dismiss()
            }
        )
    }

    @MainActor
    public func dismissFloatingWindow() {
        RadialMenuWindowController.shared.dismiss()
        self.isFloatingWindowActive = false
    }
}
