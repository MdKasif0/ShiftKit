import Foundation
import AppKit
import Observation

// MARK: - Drag Session State
public enum DragSessionState: Equatable, Sendable {
    case idle
    case shiftHeld
    case dragging(location: CGPoint)
    case dropDestinationActive(location: CGPoint)
    case processing(count: Int)
}

// MARK: - Drag Session Coordinator
@Observable
public final class DragSessionCoordinator: @unchecked Sendable {
    public static let shared = DragSessionCoordinator()

    public private(set) var currentState: DragSessionState = .idle
    public private(set) var lastValidatedFiles: [ValidatedFile] = []
    public var lastErrorMessage: String?

    private let keyTracker = ModifierKeyTracker.shared
    private let eventMonitor = GlobalEventMonitor.shared
    private let fileAccessManager = FileAccessManager.shared
    private let permissionManager = InteractionPermissionManager.shared

    private weak var appCoordinator: AppCoordinator?
    private var isListening: Bool = false
    private let lock = NSLock()

    private init() {}

    public func configure(appCoordinator: AppCoordinator) {
        self.appCoordinator = appCoordinator
        startListening()
    }

    public func startListening() {
        guard !isListening else { return }
        isListening = true

        keyTracker.startTracking()
        eventMonitor.start()

        // 1. Shift key change listener
        keyTracker.onShiftStateChanged { [weak self] isShift in
            guard let self else { return }
            if isShift && self.currentState == .idle {
                self.currentState = .shiftHeld
            } else if !isShift && self.currentState == .shiftHeld {
                self.currentState = .idle
            }
        }

        // 2. Global Shift + Drag detection hook
        eventMonitor.onShiftDragDetected = { [weak self] mouseLocation in
            guard let self else { return }
            DispatchQueue.main.async {
                self.handleShiftDragAt(mouseLocation)
            }
        }

        // 3. Drag ended hook
        eventMonitor.onDragEnded = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                if case .dropDestinationActive = self.currentState {
                    // Reset state
                    self.currentState = .idle
                }
            }
        }

        // 4. Fallback Global Shortcut (Option + Shift + S)
        eventMonitor.onGlobalShortcutTriggered = { [weak self] in
            DispatchQueue.main.async {
                self?.summonFloatingTargetAtCursor()
            }
        }
    }

    /// Handles a detected Shift + drag interaction originating from Finder or Desktop.
    public func handleShiftDragAt(_ mouseLocation: CGPoint) {
        guard currentState != .dropDestinationActive(location: mouseLocation) else { return }
        currentState = .dropDestinationActive(location: mouseLocation)

        // Present floating drop destination window at cursor
        RadialMenuWindowController.shared.present(
            for: makeFallbackInspectedFile(at: mouseLocation),
            at: mouseLocation,
            onSelectAction: { [weak self] action in
                self?.handleActionTriggered(action)
            },
            onDismiss: { [weak self] in
                self?.currentState = .idle
            }
        )
    }

    /// Primary fallback shortcut trigger (<kbd>⌥⇧S</kbd>)
    public func summonFloatingTargetAtCursor() {
        let cursor = NSEvent.mouseLocation
        currentState = .dropDestinationActive(location: cursor)

        RadialMenuWindowController.shared.present(
            for: makeFallbackInspectedFile(at: cursor),
            at: cursor,
            onSelectAction: { [weak self] action in
                self?.handleActionTriggered(action)
            },
            onDismiss: { [weak self] in
                self?.currentState = .idle
            }
        )
    }

    /// Processes files received via native AppKit NSDraggingDestination
    public func handleDroppedURLs(_ urls: [URL], onSegmentIndex: Int?) {
        let validationResult = fileAccessManager.validateURLs(urls)

        switch validationResult {
        case .success(let validatedFiles):
            self.lastValidatedFiles = validatedFiles
            guard let first = validatedFiles.first else { return }

            Task { @MainActor in
                guard let appCoordinator = self.appCoordinator else { return }
                do {
                    let inspected = try await appCoordinator.fileInspector.inspect(url: first.resolvedURL)
                    let registry = ConversionRegistry()
                    let segments = registry.segments(for: inspected.fileType)

                    if let segmentIdx = onSegmentIndex, segmentIdx >= 0 && segmentIdx < segments.count {
                        // Directly execute the first action of the targeted slice!
                        let targetSegment = segments[segmentIdx]
                        if let action = targetSegment.subActions.first {
                            for file in validatedFiles {
                                let item = try await appCoordinator.fileInspector.inspect(url: file.resolvedURL)
                                appCoordinator.executeAction(action, on: item)
                            }
                        }
                    } else {
                        // Dropped on center hub -> open radial menu to let user pick action
                        appCoordinator.inspectedFile = inspected
                        appCoordinator.radialMenuCoordinator.presentFloatingWindow(for: inspected) { action in
                            for file in validatedFiles {
                                if let item = try? await appCoordinator.fileInspector.inspect(url: file.resolvedURL) {
                                    appCoordinator.executeAction(action, on: item)
                                }
                            }
                        }
                    }
                } catch {
                    self.lastErrorMessage = "Inspection error: \(error.localizedDescription)"
                }
            }

        case .failure(let error):
            self.lastErrorMessage = error.localizedDescription
        }
    }

    private func handleActionTriggered(_ action: ConversionAction) {
        currentState = .idle
    }

    private func makeFallbackInspectedFile(at location: CGPoint) -> InspectedFile {
        InspectedFile(
            url: URL(fileURLWithPath: "/tmp/ShiftKitDropTarget"),
            fileName: "Drop Target",
            fileType: .image(.png),
            metadata: FileMetadata(fileSize: 0, fileExtension: "drop")
        )
    }
}
