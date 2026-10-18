import Foundation
import SwiftUI
import Observation

@Observable
public final class RadialMenuCoordinator: @unchecked Sendable {
    public var isPresented: Bool = false
    public var currentFile: InspectedFile?
    public var availableActions: [ConversionAction] = []
    public var hoveredAction: ConversionAction?
    public var menuPosition: CGPoint = .zero
    public var isSimulatingShiftDrag: Bool = false

    private let registry: ConversionRegistering

    public init(registry: ConversionRegistering = ConversionRegistry()) {
        self.registry = registry
    }

    public func present(for file: InspectedFile, at position: CGPoint = .zero) {
        self.currentFile = file
        self.availableActions = registry.actions(for: file.fileType)
        self.hoveredAction = availableActions.first
        self.menuPosition = position
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            self.isPresented = true
        }
    }

    public func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            self.isPresented = false
            self.hoveredAction = nil
        }
    }

    public func selectAction(_ action: ConversionAction) {
        dismiss()
    }
}
