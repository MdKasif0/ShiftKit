import Foundation
import Observation
import AppKit

@Observable
public final class AppCoordinator: @unchecked Sendable {
    public let jobManager: JobManager
    public let radialMenuCoordinator: RadialMenuCoordinator
    public let conversionRouter: ConversionRouting
    public let settingsStore: SettingsStore
    public let fileInspector: FileInspecting
    public let outputManager: OutputManaging
    public let dragMonitor: DragEventMonitoring
    public let dragSessionCoordinator: DragSessionCoordinator
    public let permissionManager: InteractionPermissionManager

    public var inspectedFile: InspectedFile?
    public var isSettingsPresented: Bool = false
    public var statusMessage: String?

    public private(set) var menuBarCoordinator: MenuBarCoordinator?

    public init(
        jobManager: JobManager? = nil,
        radialMenuCoordinator: RadialMenuCoordinator? = nil,
        conversionRouter: ConversionRouting? = nil,
        settingsStore: SettingsStore? = nil,
        fileInspector: FileInspecting? = nil,
        outputManager: OutputManaging? = nil,
        dragMonitor: DragEventMonitoring = DragEventMonitor.shared
    ) {
        let settings = settingsStore ?? SettingsStore()
        let output = outputManager ?? OutputManager()
        let router = conversionRouter ?? ConversionRouter(outputManager: output)
        let jobs = jobManager ?? JobManager(router: router, outputManager: output)
        let radial = radialMenuCoordinator ?? RadialMenuCoordinator()
        let inspector = fileInspector ?? FileInspector()

        self.settingsStore = settings
        self.outputManager = output
        self.conversionRouter = router
        self.jobManager = jobs
        self.radialMenuCoordinator = radial
        self.fileInspector = inspector
        self.dragMonitor = dragMonitor
        self.dragSessionCoordinator = DragSessionCoordinator.shared
        self.permissionManager = InteractionPermissionManager.shared

        // Seed preview jobs if empty
        if self.jobManager.completedJobs.isEmpty {
            self.jobManager.populateSampleJobsForPreview()
        }

        self.menuBarCoordinator = MenuBarCoordinator(appCoordinator: self)

        // Initialize drag session coordination
        self.dragSessionCoordinator.configure(appCoordinator: self)
    }

    @MainActor
    public func startMenuBar() {
        menuBarCoordinator?.setupStatusBarItem()
    }

    /// Handles a file dropped onto the app or detected via Shift+Drag
    public func handleFileSelected(url: URL) {
        Task { @MainActor in
            do {
                let file = try await fileInspector.inspect(url: url)
                self.inspectedFile = file
                self.radialMenuCoordinator.present(for: file)
            } catch {
                self.statusMessage = "Inspection failed: \(error.localizedDescription)"
            }
        }
    }

    /// Handles multiple files dropped at once
    public func handleBatchFilesSelected(urls: [URL]) {
        guard let first = urls.first else { return }
        Task { @MainActor in
            do {
                let file = try await fileInspector.inspect(url: first)
                self.inspectedFile = file
                self.radialMenuCoordinator.present(for: file)
            } catch {
                self.statusMessage = "Inspection failed: \(error.localizedDescription)"
            }
        }
    }

    /// Dispatches an operation for execution
    public func executeAction(_ action: ConversionAction, on file: InspectedFile) {
        let customDir = URL(fileURLWithPath: settingsStore.outputDirectoryPath)
        let destinationURL = outputManager.resolveDestinationURL(
            for: file.url,
            targetExtension: action.targetFormat,
            suffix: action.category.rawValue,
            customDirectory: customDir
        )

        let request = ConversionRequest(
            sourceURL: file.url,
            fileType: file.fileType,
            action: action,
            destinationURL: destinationURL
        )

        jobManager.enqueue(request: request)

        // Clear active inspected file
        self.inspectedFile = nil
        self.radialMenuCoordinator.dismiss()
    }

    public func summonFloatingTargetAtCursor() {
        dragSessionCoordinator.summonFloatingTargetAtCursor()
    }

    public func revealInFinder(url: URL) {
        outputManager.revealInFinder(url: url)
    }

    public func clearCompleted() {
        jobManager.clearCompletedJobs()
    }
}
