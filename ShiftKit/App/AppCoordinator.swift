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
        if urls.count > 1 {
            // Present dedicated Merge Studio for multiple files
            Task { @MainActor in
                self.radialMenuCoordinator.dismiss()
                MergeWindowController.shared.present(for: urls) { [weak self] orderedURLs, workflow, options in
                    self?.executeMerge(urls: orderedURLs, workflow: workflow, options: options)
                }
            }
            return
        }

        guard let first = urls.first else { return }
        handleFileSelected(url: first)
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

        // If merge action is selected, present the dedicated visual Merge Studio
        if action.category == .merge || action.id == "pdf_merge" || action.id == "audio_merge" || action.id == "vid_merge" {
            self.radialMenuCoordinator.dismiss()
            MergeWindowController.shared.present(for: [file.url]) { [weak self] orderedURLs, workflow, options in
                self?.executeMerge(urls: orderedURLs, workflow: workflow, options: options)
            }
            return
        }

        // If metadata inspection or cleaning is selected, present the dedicated Metadata Inspector
        if action.category == .metadata || action.id == "img_strip_exif" || action.id == "pdf_strip_metadata" || action.id == "audio_edit_tags" {
            self.radialMenuCoordinator.dismiss()
            MetadataInspectorWindowController.shared.present(for: file) { [weak self] inspected, options, isStrip in
                self?.executeMetadataOperation(file: inspected, options: options, isStrip: isStrip)
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

    private func executeMerge(urls: [URL], workflow: MergeWorkflowType, options: [String: String]) {
        guard let first = urls.first else { return }
        let customDir = URL(fileURLWithPath: settingsStore.outputDirectoryPath)
        let outputExt = options["targetFormat"] ?? (workflow == .pdf || workflow == .imagesToPDF ? "pdf" : first.pathExtension)
        let outName = options["outputName"] ?? "Merged_Files"
        let destinationURL = customDir.appendingPathComponent("\(outName).\(outputExt)")

        var requestOptions = options
        let additional = urls.dropFirst().map { $0.path }.joined(separator: ",")
        requestOptions["additionalFiles"] = additional

        let actionID: String
        let fileType: FileType
        switch workflow {
        case .pdf:
            actionID = "pdf_merge"
            fileType = .pdf
        case .imagesToPDF:
            actionID = "img_to_pdf"
            fileType = .image(.png)
        case .audio:
            actionID = "audio_merge"
            fileType = .audio(.mp3)
        case .video:
            actionID = "vid_merge"
            fileType = .video(.mp4)
        case .incompatible:
            return
        }

        let mergeAction = ConversionAction(
            id: actionID,
            title: "Merge \(urls.count) Files",
            subtitle: workflow.rawValue,
            systemIcon: workflow.systemIcon,
            category: .merge,
            targetFormat: outputExt,
            options: requestOptions
        )

        let request = ConversionRequest(
            sourceURL: first,
            fileType: fileType,
            action: mergeAction,
            destinationURL: destinationURL,
            options: requestOptions
        )

        jobManager.enqueue(request: request)
        self.inspectedFile = nil
    }

    private func executeMetadataOperation(file: InspectedFile, options: [String: String], isStrip: Bool) {
        let customDir = URL(fileURLWithPath: settingsStore.outputDirectoryPath)
        let suffix = isStrip ? "clean" : "metadata"
        let destinationURL = outputManager.resolveDestinationURL(
            for: file.url,
            targetExtension: file.url.pathExtension,
            suffix: suffix,
            customDirectory: customDir
        )

        var requestOptions = options
        if isStrip {
            requestOptions["stripMetadata"] = "true"
        }

        let actionID: String
        switch file.fileType {
        case .pdf:
            actionID = isStrip ? "pdf_strip_metadata" : "pdf_edit_metadata"
        case .image:
            actionID = "img_strip_exif"
        case .audio:
            actionID = isStrip ? "audio_strip_tags" : "audio_edit_tags"
        default:
            actionID = "file_inspect"
        }

        let metaAction = ConversionAction(
            id: actionID,
            title: isStrip ? "Clean Metadata" : "Update Metadata",
            subtitle: file.url.lastPathComponent,
            systemIcon: isStrip ? "eye.slash" : "info.circle",
            category: .metadata,
            targetFormat: file.url.pathExtension,
            options: requestOptions
        )

        let request = ConversionRequest(
            sourceURL: file.url,
            fileType: file.fileType,
            action: metaAction,
            destinationURL: destinationURL,
            options: requestOptions
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

    public func openSettingsWindow() {
        SettingsWindowController.shared.present()
    }

    public func openJobQueueWindow() {
        JobQueueWindowController.shared.present()
    }
}
