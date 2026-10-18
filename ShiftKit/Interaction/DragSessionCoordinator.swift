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
@MainActor
public final class DragSessionCoordinator {
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
            Task { @MainActor [weak self] in
                guard let self else { return }
                if isShift && self.currentState == .idle {
                    self.currentState = .shiftHeld
                } else if !isShift {
                    if case .dropDestinationActive = self.currentState {
                        self.currentState = .idle
                        RadialMenuWindowController.shared.dismiss()
                    } else if self.currentState == .shiftHeld {
                        self.currentState = .idle
                    }
                }
            }
        }

        // 2. Global Shift + Drag detection hook
        eventMonitor.onShiftDragDetected = { [weak self] mouseLocation in
            Task { @MainActor [weak self] in
                self?.handleShiftDragAt(mouseLocation)
            }
        }

        // 3. Drag ended hook
        eventMonitor.onDragEnded = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if case .dropDestinationActive = self.currentState {
                    self.currentState = .idle
                    RadialMenuWindowController.shared.dismiss()
                }
            }
        }

        // 4. Fallback Global Shortcut (Option + Shift + S)
        eventMonitor.onGlobalShortcutTriggered = { [weak self] in
            Task { @MainActor [weak self] in
                self?.summonFloatingTargetAtCursor()
            }
        }
    }

    /// Handles a detected Shift + drag interaction originating from Finder or Desktop.
    public func handleShiftDragAt(_ mouseLocation: CGPoint) {
        // If drop destination is already presented or active, do not recreate!
        if case .dropDestinationActive = currentState {
            return
        }
        if RadialMenuWindowController.shared.isVisible {
            return
        }
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

    /// Primary fallback shortcut trigger (Option + Shift + S)
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
                    let registry = ConversionRegistry.shared
                    let segments = registry.segments(for: inspected)

                    if let segmentIdx = onSegmentIndex, segmentIdx >= 0 && segmentIdx < segments.count {
                        self.currentState = .idle
                        let targetSegment = segments[segmentIdx]
                        if let action = targetSegment.subActions.first {
                            for file in validatedFiles {
                                let item = try await appCoordinator.fileInspector.inspect(url: file.resolvedURL)
                                appCoordinator.executeAction(action, on: item)
                            }
                        } else {
                            let fallbackAction = ConversionAction(
                                id: targetSegment.id,
                                title: targetSegment.title,
                                subtitle: targetSegment.subtitle,
                                systemIcon: targetSegment.systemIcon,
                                category: targetSegment.category
                            )
                            for file in validatedFiles {
                                let item = try await appCoordinator.fileInspector.inspect(url: file.resolvedURL)
                                appCoordinator.executeAction(fallbackAction, on: item)
                            }
                        }
                    } else {
                        // Dropped on center hub -> open radial menu for this inspected file to let user choose action
                        self.currentState = .idle
                        appCoordinator.inspectedFile = inspected
                        appCoordinator.radialMenuCoordinator.presentFloatingWindow(for: inspected) { action in
                            for file in validatedFiles {
                                Task {
                                    if let item = try? await appCoordinator.fileInspector.inspect(url: file.resolvedURL) {
                                        appCoordinator.executeAction(action, on: item)
                                    }
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
        if let first = lastValidatedFiles.first {
            Task { @MainActor in
                if let item = try? await appCoordinator?.fileInspector.inspect(url: first.resolvedURL) {
                    appCoordinator?.executeAction(action, on: item)
                }
            }
        } else {
            chooseFileForAction(action)
        }
    }

    private func chooseFileForAction(_ action: ConversionAction) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose File"
        panel.message = "Select a file to run \(action.title)"
        if panel.runModal() == .OK, let url = panel.url {
            Task { @MainActor in
                if let item = try? await appCoordinator?.fileInspector.inspect(url: url) {
                    appCoordinator?.executeAction(action, on: item)
                }
            }
        }
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
