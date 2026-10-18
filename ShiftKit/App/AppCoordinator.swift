import Foundation
import Observation
import AppKit

@Observable
@MainActor
public final class AppCoordinator {
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
        // If image crop action is selected, present the dedicated visual crop editor
        if (action.category == .cropOrTrim || action.id == "img_crop_square"), case .image = file.fileType {
            self.radialMenuCoordinator.dismiss()
            CropEditorWindowController.shared.present(for: file) { [weak self] cropRect, options, targetFormat in
                self?.executeCroppedImageProcessing(
                    file: file,
                    action: action,
                    cropRect: cropRect,
                    options: options,
                    targetFormat: targetFormat
                )
            }
            return
        }

        // If video trim action is selected, present the dedicated visual video trim editor
        if (action.category == .cropOrTrim || action.id == "vid_trim"), case .video = file.fileType {
            self.radialMenuCoordinator.dismiss()
            VideoTrimWindowController.shared.present(for: file) { [weak self] start, end, options, targetFormat in
                self?.executeTrimmedVideoProcessing(
                    file: file,
                    action: action,
                    start: start,
                    end: end,
                    options: options,
                    targetFormat: targetFormat
                )
            }
            return
        }

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

    private func executeCroppedImageProcessing(
        file: InspectedFile,
        action: ConversionAction,
        cropRect: CGRect,
        options: ConversionOptions,
        targetFormat: OutputFormat
    ) {
        let customDir = URL(fileURLWithPath: settingsStore.outputDirectoryPath)
        let destinationURL = outputManager.resolveDestinationURL(
            for: file.url,
            targetExtension: targetFormat.primaryExtension,
            suffix: "crop",
            customDirectory: customDir
        )

        var requestOptions = options.stringDictionary
        requestOptions["cropRect"] = NSStringFromRect(cropRect)

        let customAction = ConversionAction(
            id: "img_crop_custom",
            title: "Crop Image",
            subtitle: "\(Int(cropRect.width)) × \(Int(cropRect.height)) px",
            systemIcon: "crop",
            category: .cropOrTrim,
            targetFormat: targetFormat.primaryExtension,
            options: requestOptions
        )

        let request = ConversionRequest(
            sourceURL: file.url,
            fileType: file.fileType,
            action: customAction,
            destinationURL: destinationURL,
            options: requestOptions,
            conversionOptions: options
        )

        jobManager.enqueue(request: request)
        self.inspectedFile = nil
    }

    private func executeTrimmedVideoProcessing(
        file: InspectedFile,
        action: ConversionAction,
        start: Double,
        end: Double,
        options: ConversionOptions,
        targetFormat: OutputFormat
    ) {
        let customDir = URL(fileURLWithPath: settingsStore.outputDirectoryPath)
        let destinationURL = outputManager.resolveDestinationURL(
            for: file.url,
            targetExtension: targetFormat.primaryExtension,
            suffix: "trim",
            customDirectory: customDir
        )

        var requestOptions = options.stringDictionary
        requestOptions["trimStart"] = String(format: "%.3f", start)
        requestOptions["trimEnd"] = String(format: "%.3f", end)

        let customAction = ConversionAction(
            id: "vid_trim_custom",
            title: "Trim Video",
            subtitle: "\(TrimGeometryEngine.formatTimestamp(start)) – \(TrimGeometryEngine.formatTimestamp(end))",
            systemIcon: "scissors",
            category: .cropOrTrim,
            targetFormat: targetFormat.primaryExtension,
            options: requestOptions
        )

        let request = ConversionRequest(
            sourceURL: file.url,
            fileType: file.fileType,
            action: customAction,
            destinationURL: destinationURL,
            options: requestOptions,
            conversionOptions: options
        )

        jobManager.enqueue(request: request)
        self.inspectedFile = nil
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
