import Foundation

// MARK: - Protocol
public protocol ConversionRegistering: Sendable {
    func segments(for fileType: FileType) -> [RadialSegmentItem]
    func segments(for file: InspectedFile) -> [RadialSegmentItem]
    func actions(for fileType: FileType) -> [ConversionAction]
    func actions(for file: InspectedFile) -> [ConversionAction]
    func defaultAction(for fileType: FileType) -> ConversionAction?
    func searchableActions(for fileType: FileType, query: String) -> [ConversionAction]

    // Universal Capability Engine APIs
    func registeredCapabilities() -> [ConversionCapability]
    func implementedCapabilities() -> [ConversionCapability]
    func capabilities(for sourceFormat: OutputFormat) -> [ConversionCapability]
    func capability(from source: OutputFormat, to target: OutputFormat, category: ActionCategory) -> ConversionCapability?
    func availableOutputFormats(for sourceFormat: OutputFormat) -> [OutputFormat]
    
    // Multi-File Validation
    func validateBatch(files: [InspectedFile], targetFormat: OutputFormat, category: ActionCategory) -> BatchValidationResult
    func validateMerge(files: [InspectedFile], targetFormat: OutputFormat) -> MergeValidationResult
}

// MARK: - Implementation
public final class ConversionRegistry: ConversionRegistering {
    public static let shared = ConversionRegistry()

    private let capabilitiesTable: [ConversionCapability]
    private let formatsTable: [String: OutputFormat]

    public init() {
        var formats: [String: OutputFormat] = [:]
        for f in OutputFormat.allCanonical {
            formats[f.id] = f
            for ext in f.recognizedExtensions {
                formats[ext] = f
            }
        }
        self.formatsTable = formats
        self.capabilitiesTable = Self.buildUniversalCapabilities()
    }

    // MARK: - Format & Capability Lookups
    public func registeredCapabilities() -> [ConversionCapability] {
        capabilitiesTable
    }

    public func implementedCapabilities() -> [ConversionCapability] {
        capabilitiesTable.filter { $0.isImplemented }
    }

    public func capabilities(for sourceFormat: OutputFormat) -> [ConversionCapability] {
        capabilitiesTable.filter { $0.sourceFormatID == sourceFormat.id }
    }

    public func capability(from source: OutputFormat, to target: OutputFormat, category: ActionCategory = .convert) -> ConversionCapability? {
        capabilitiesTable.first {
            $0.sourceFormatID == source.id &&
            $0.targetFormatID == target.id &&
            $0.actionCategory == category
        }
    }

    public func availableOutputFormats(for sourceFormat: OutputFormat) -> [OutputFormat] {
        let targets = capabilitiesTable
            .filter { $0.sourceFormatID == sourceFormat.id && $0.isImplemented }
            .compactMap { $0.targetFormat }
        return Array(Set(targets)).sorted { $0.displayName < $1.displayName }
    }

    // MARK: - Radial Menu Integration (Contextual & Dynamic)
    public func segments(for fileType: FileType) -> [RadialSegmentItem] {
        let sourceFormat = mapFileTypeToFormat(fileType)
        return buildDynamicSegments(sourceFormat: sourceFormat, fileType: fileType)
    }

    public func segments(for file: InspectedFile) -> [RadialSegmentItem] {
        let sourceFormat = file.metadata.detectedFormat ?? mapFileTypeToFormat(file.fileType)
        return buildDynamicSegments(sourceFormat: sourceFormat, fileType: file.fileType)
    }

    public func actions(for fileType: FileType) -> [ConversionAction] {
        let segs = segments(for: fileType)
        return segs.flatMap { $0.subActions }
    }

    public func actions(for file: InspectedFile) -> [ConversionAction] {
        let segs = segments(for: file)
        return segs.flatMap { $0.subActions }
    }

    public func defaultAction(for fileType: FileType) -> ConversionAction? {
        actions(for: fileType).first
    }

    public func searchableActions(for fileType: FileType, query: String) -> [ConversionAction] {
        let all = actions(for: fileType)
        guard !query.isEmpty else { return all }
        let clean = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return all.filter {
            $0.title.lowercased().contains(clean) ||
            $0.subtitle.lowercased().contains(clean) ||
            ($0.targetFormat?.lowercased().contains(clean) ?? false)
        }
    }

    // MARK: - Multi-File Batch & Merge Validation
    public func validateBatch(
        files: [InspectedFile],
        targetFormat: OutputFormat,
        category: ActionCategory = .convert
    ) -> BatchValidationResult {
        var results: [URL: ConversionValidationResult] = [:]
        var supported: [InspectedFile] = []
        var unsupported: [(file: InspectedFile, reason: String)] = []

        for file in files {
            let sourceFormat = file.metadata.detectedFormat ?? mapFileTypeToFormat(file.fileType)
            if let cap = capability(from: sourceFormat, to: targetFormat, category: category), cap.isImplemented {
                supported.append(file)
                results[file.url] = .valid(
                    capability: cap,
                    isLossless: cap.isLossless
                )
            } else {
                let reason = "Cannot convert \(sourceFormat.displayName) to \(targetFormat.displayName) - unsupported capability."
                unsupported.append((file, reason))
                results[file.url] = .invalid(reason: reason)
            }
        }

        // Conflict check on destination names in common folder
        var destinations: [String: [URL]] = [:]
        for file in supported {
            let baseName = file.url.deletingPathExtension().lastPathComponent
            let targetName = "\(baseName).\(targetFormat.primaryExtension)"
            destinations[targetName, default: []].append(file.url)
        }

        var conflicts: [URL: [URL]] = [:]
        for (_, urls) in destinations where urls.count > 1 {
            if let first = urls.first {
                conflicts[first] = urls
            }
        }

        return BatchValidationResult(
            targetFormat: targetFormat,
            fileResults: results,
            supportedFiles: supported,
            unsupportedFiles: unsupported,
            outputNameConflicts: conflicts
        )
    }

    public func validateMerge(
        files: [InspectedFile],
        targetFormat: OutputFormat
    ) -> MergeValidationResult {
        guard !files.isEmpty else {
            return MergeValidationResult(canMerge: false, targetFormat: targetFormat, compatibleFiles: [], incompatibleFiles: [], failureReason: "No files selected for merge.")
        }

        if targetFormat == .pdf {
            var compatible: [InspectedFile] = []
            var incompatible: [(file: InspectedFile, reason: String)] = []

            for file in files {
                let format = file.metadata.detectedFormat ?? mapFileTypeToFormat(file.fileType)
                if format == .pdf || format.category == .image {
                    compatible.append(file)
                } else {
                    incompatible.append((file, "Files of category \(format.category.displayName) cannot be merged into a PDF document."))
                }
            }

            let canMerge = incompatible.isEmpty && compatible.count >= 2
            let reason = incompatible.isEmpty ? nil : "Mixed selection contains incompatible media streams that cannot be bound into a single PDF."
            return MergeValidationResult(canMerge: canMerge, targetFormat: targetFormat, compatibleFiles: compatible, incompatibleFiles: incompatible, failureReason: reason)
        }

        // Default: Verify all files share the target format category
        let allMatch = files.allSatisfy { file in
            let f = file.metadata.detectedFormat ?? mapFileTypeToFormat(file.fileType)
            return f.category == targetFormat.category
        }

        if allMatch && files.count >= 2 {
            return MergeValidationResult(canMerge: true, targetFormat: targetFormat, compatibleFiles: files, incompatibleFiles: [])
        } else {
            return MergeValidationResult(canMerge: false, targetFormat: targetFormat, compatibleFiles: [], incompatibleFiles: files.map { ($0, "Incompatible format") }, failureReason: "Cannot merge mixed file types into \(targetFormat.displayName).")
        }
    }

    // MARK: - Private Dynamic Segment Generation
    private func buildDynamicSegments(sourceFormat: OutputFormat, fileType: FileType) -> [RadialSegmentItem] {
        let implementedCaps = capabilitiesTable.filter { $0.sourceFormatID == sourceFormat.id && $0.isImplemented }

        // 1. Convert Segment
        let convertCaps = implementedCaps.filter { $0.actionCategory == .convert }
        let convertActions: [ConversionAction] = convertCaps.compactMap { cap in
            guard let target = cap.targetFormat else { return nil }
            return ConversionAction(
                id: cap.id,
                title: "To \(target.primaryExtension.uppercased())",
                subtitle: cap.displayName,
                systemIcon: target.category.defaultIcon,
                category: .convert,
                targetFormat: target.primaryExtension,
                badgeTag: cap.isLossless ? "Lossless" : nil
            )
        }

        // 2. Compress Segment
        let compressCaps = implementedCaps.filter { $0.actionCategory == .compress }
        let compressActions: [ConversionAction] = compressCaps.compactMap { cap in
            ConversionAction(
                id: cap.id,
                title: cap.displayName,
                subtitle: cap.knownLimitations.first ?? "Reduce file size",
                systemIcon: "arrow.down.forward.and.arrow.up.backward",
                category: .compress,
                targetFormat: cap.targetFormatID,
                badgeTag: "Optimized"
            )
        }

        // 3. Crop / Trim Segment
        let cropTrimCaps = implementedCaps.filter { $0.actionCategory == .cropOrTrim }
        let cropTrimActions: [ConversionAction] = cropTrimCaps.compactMap { cap in
            ConversionAction(
                id: cap.id,
                title: cap.displayName,
                subtitle: cap.knownLimitations.first ?? "Adjust bounds",
                systemIcon: fileType.isMedia ? "scissors" : "crop",
                category: .cropOrTrim,
                targetFormat: cap.targetFormatID
            )
        }

        // 4. Merge Segment
        let mergeCaps = implementedCaps.filter { $0.actionCategory == .merge }
        let mergeActions: [ConversionAction] = mergeCaps.compactMap { cap in
            ConversionAction(
                id: cap.id,
                title: cap.displayName,
                subtitle: "Combine into single \(cap.targetFormatID.uppercased())",
                systemIcon: "doc.on.doc",
                category: .merge,
                targetFormat: cap.targetFormatID
            )
        }

        // 5. Edit Segment
        let editCaps = implementedCaps.filter { $0.actionCategory == .edit }
        let editActions: [ConversionAction] = editCaps.compactMap { cap in
            ConversionAction(
                id: cap.id,
                title: cap.displayName,
                subtitle: cap.knownLimitations.first ?? "Adjust properties",
                systemIcon: "slider.horizontal.3",
                category: .edit,
                targetFormat: cap.targetFormatID
            )
        }

        // 6. Metadata Segment
        let metaCaps = implementedCaps.filter { $0.actionCategory == .metadata }
        let metaActions: [ConversionAction] = metaCaps.compactMap { cap in
            ConversionAction(
                id: cap.id,
                title: cap.displayName,
                subtitle: cap.knownLimitations.first ?? "Manage metadata",
                systemIcon: "info.circle",
                category: .metadata,
                targetFormat: cap.targetFormatID
            )
        }

        // 7. Extract Segment
        let extractCaps = implementedCaps.filter { $0.actionCategory == .extract }
        let extractActions: [ConversionAction] = extractCaps.compactMap { cap in
            ConversionAction(
                id: cap.id,
                title: cap.displayName,
                subtitle: cap.knownLimitations.first ?? "Extract stream",
                systemIcon: "arrow.up.right.and.arrow.down.left.rectangle",
                category: .extract,
                targetFormat: cap.targetFormatID
            )
        }

        // 8. More Segment
        let moreActions: [ConversionAction] = [
            ConversionAction(id: "more_info", title: "File Details", subtitle: "UTI & Properties", systemIcon: "doc.text.magnifyingglass", category: .more),
            ConversionAction(id: "more_copy_path", title: "Copy Path", subtitle: "Absolute location", systemIcon: "link", category: .more)
        ]

        let (cropTitle, cropIcon): (String, String) = {
            switch fileType {
            case .video, .audio:
                return ("Trim", "scissors")
            case .image, .pdf:
                return ("Crop", "crop")
            default:
                return ("Crop/Trim", "scissors")
            }
        }()

        return [
            RadialSegmentItem(
                id: "seg_convert",
                title: "Convert",
                subtitle: "\(convertActions.count) formats",
                systemIcon: "arrow.triangle.2.circlepath",
                shortcutKey: "1",
                category: .convert,
                isEnabled: !convertActions.isEmpty,
                subActions: convertActions
            ),
            RadialSegmentItem(
                id: "seg_compress",
                title: "Compress",
                subtitle: "Reduce weight",
                systemIcon: "arrow.down.forward.and.arrow.up.backward",
                shortcutKey: "2",
                category: .compress,
                isEnabled: !compressActions.isEmpty,
                subActions: compressActions
            ),
            RadialSegmentItem(
                id: "seg_crop_trim",
                title: cropTitle,
                subtitle: fileType.isMedia ? "Time boundaries" : "Pixel margins",
                systemIcon: cropIcon,
                shortcutKey: "3",
                category: .cropOrTrim,
                isEnabled: !cropTrimActions.isEmpty,
                subActions: cropTrimActions
            ),
            RadialSegmentItem(
                id: "seg_merge",
                title: "Merge",
                subtitle: "Combine files",
                systemIcon: "doc.on.doc",
                shortcutKey: "4",
                category: .merge,
                isEnabled: !mergeActions.isEmpty,
                subActions: mergeActions
            ),
            RadialSegmentItem(
                id: "seg_edit",
                title: "Edit",
                subtitle: "Adjust properties",
                systemIcon: "slider.horizontal.3",
                shortcutKey: "5",
                category: .edit,
                isEnabled: !editActions.isEmpty,
                subActions: editActions
            ),
            RadialSegmentItem(
                id: "seg_metadata",
                title: "Metadata",
                subtitle: "EXIF & privacy",
                systemIcon: "info.circle",
                shortcutKey: "6",
                category: .metadata,
                isEnabled: !metaActions.isEmpty,
                subActions: metaActions
            ),
            RadialSegmentItem(
                id: "seg_extract",
                title: "Extract",
                subtitle: "Assets & audio",
                systemIcon: "arrow.up.right.and.arrow.down.left.rectangle",
                shortcutKey: "7",
                category: .extract,
                isEnabled: !extractActions.isEmpty,
                subActions: extractActions
            ),
            RadialSegmentItem(
                id: "seg_more",
                title: "More",
                subtitle: "Inspection",
                systemIcon: "ellipsis.circle",
                shortcutKey: "8",
                category: .more,
                isEnabled: true,
                subActions: moreActions
            )
        ]
    }

    private func mapFileTypeToFormat(_ fileType: FileType) -> OutputFormat {
        switch fileType {
        case .image(let sub):
            return OutputFormat.find(byExtension: sub.rawValue) ?? .png
        case .video(let sub):
            return OutputFormat.find(byExtension: sub.rawValue) ?? .mp4
        case .audio(let sub):
            return OutputFormat.find(byExtension: sub.rawValue) ?? .wav
        case .pdf:
            return .pdf
        case .archive:
            return .zip
        case .document(let sub):
            return OutputFormat.find(byExtension: sub.rawValue) ?? .txt
        case .unknown(let ext):
            return OutputFormat.find(byExtension: ext) ?? .txt
        }
    }

    // MARK: - Capabilities Matrix Factory
    private static func buildUniversalCapabilities() -> [ConversionCapability] {
        var caps: [ConversionCapability] = []

        // ==========================================
        // 1. IMAGES (ImageIO & CoreGraphics Engine)
        // ==========================================
        let imageFormats: [OutputFormat] = [.png, .jpeg, .webp, .heic, .tiff]
        for src in imageFormats {
            for tgt in imageFormats where src.id != tgt.id {
                let isLossless = !tgt.isContainerLossy && !src.isContainerLossy
                var limitations: [String] = []
                if src.supportsAlpha && !tgt.supportsAlpha {
                    limitations.append("Alpha channel flattened to matte background")
                }
                if src.isContainerLossy && !tgt.isContainerLossy {
                    limitations.append("Lossy source does not restore original detail")
                }

                caps.append(ConversionCapability(
                    id: "img_to_\(tgt.id)",
                    displayName: "Convert to \(tgt.primaryExtension.uppercased())",
                    category: .image,
                    actionCategory: .convert,
                    sourceFormatID: src.id,
                    targetFormatID: tgt.id,
                    requiredEngineID: "com.shiftkit.engine.imageio",
                    requiredCodecs: ["ImageIO"],
                    supportedOptionKeys: ["quality", "preserveAlpha", "stripMetadata"],
                    knownLimitations: limitations,
                    isLossless: isLossless,
                    isImplemented: true
                ))
            }

            // Image Compression
            caps.append(ConversionCapability(
                id: "img_compress",
                displayName: "Compress \(src.primaryExtension.uppercased())",
                category: .image,
                actionCategory: .compress,
                sourceFormatID: src.id,
                targetFormatID: src.id,
                requiredEngineID: "com.shiftkit.engine.imageio",
                requiredCodecs: ["ImageIO"],
                supportedOptionKeys: ["quality", "maxDimension"],
                knownLimitations: ["Reduces pixel dimensions or compression quality"],
                isLossless: false,
                isImplemented: true
            ))

            // Image Crop
            caps.append(ConversionCapability(
                id: "img_crop_square",
                displayName: "Crop Square",
                category: .image,
                actionCategory: .cropOrTrim,
                sourceFormatID: src.id,
                targetFormatID: src.id,
                requiredEngineID: "com.shiftkit.engine.imageio",
                isImplemented: true
            ))

            // Image Strip EXIF
            caps.append(ConversionCapability(
                id: "img_strip_exif",
                displayName: "Strip EXIF & Location",
                category: .image,
                actionCategory: .metadata,
                sourceFormatID: src.id,
                targetFormatID: src.id,
                requiredEngineID: "com.shiftkit.engine.imageio",
                knownLimitations: ["Removes camera and GPS coordinates for privacy"],
                isLossless: true,
                isImplemented: true
            ))
        }

        // ==========================================
        // 2. VIDEO (AVFoundation & FFmpeg Engine)
        // ==========================================
        let videoFormats: [OutputFormat] = [.mp4, .mov]
        for src in videoFormats {
            caps.append(ConversionCapability(
                id: "vid_to_mp4",
                displayName: "Re-encode MP4",
                category: .video,
                actionCategory: .convert,
                sourceFormatID: src.id,
                targetFormatID: "mp4",
                requiredEngineID: "com.shiftkit.engine.avfoundation",
                requiredCodecs: ["h264", "aac"],
                isImplemented: true
            ))

            caps.append(ConversionCapability(
                id: "vid_compress",
                displayName: "Compress Video (720p)",
                category: .video,
                actionCategory: .compress,
                sourceFormatID: src.id,
                targetFormatID: "mp4",
                requiredEngineID: "com.shiftkit.engine.avfoundation",
                knownLimitations: ["Downscales video stream to 1280x720"],
                isImplemented: true
            ))

            caps.append(ConversionCapability(
                id: "vid_trim",
                displayName: "Trim Video Duration",
                category: .video,
                actionCategory: .cropOrTrim,
                sourceFormatID: src.id,
                targetFormatID: src.id,
                requiredEngineID: "com.shiftkit.engine.avfoundation",
                isImplemented: true
            ))

            caps.append(ConversionCapability(
                id: "vid_extract_audio",
                displayName: "Extract M4A Audio",
                category: .video,
                actionCategory: .extract,
                sourceFormatID: src.id,
                targetFormatID: "m4a",
                requiredEngineID: "com.shiftkit.engine.avfoundation",
                isImplemented: true
            ))

            // FFmpeg video to GIF
            caps.append(ConversionCapability(
                id: "vid_to_gif",
                displayName: "Convert to Animated GIF",
                category: .video,
                actionCategory: .convert,
                sourceFormatID: src.id,
                targetFormatID: "gif",
                requiredEngineID: "com.shiftkit.engine.ffmpeg",
                requiredCodecs: ["palettegen"],
                knownLimitations: ["256-color palette limitation"],
                isImplemented: true
            ))
        }

        // ==========================================
        // 3. AUDIO (AVFoundation & FFmpeg Engine)
        // ==========================================
        let audioFormats: [OutputFormat] = [.wav, .m4a, .mp3]
        for src in audioFormats {
            caps.append(ConversionCapability(
                id: "audio_to_m4a",
                displayName: "Convert to M4A (AAC)",
                category: .audio,
                actionCategory: .convert,
                sourceFormatID: src.id,
                targetFormatID: "m4a",
                requiredEngineID: "com.shiftkit.engine.avfoundation",
                isImplemented: true
            ))

            caps.append(ConversionCapability(
                id: "audio_to_mp3",
                displayName: "Convert to MP3",
                category: .audio,
                actionCategory: .convert,
                sourceFormatID: src.id,
                targetFormatID: "mp3",
                requiredEngineID: "com.shiftkit.engine.ffmpeg",
                requiredCodecs: ["libmp3lame"],
                isImplemented: true
            ))

            caps.append(ConversionCapability(
                id: "audio_compress",
                displayName: "Compress Audio",
                category: .audio,
                actionCategory: .compress,
                sourceFormatID: src.id,
                targetFormatID: "m4a",
                requiredEngineID: "com.shiftkit.engine.avfoundation",
                isImplemented: true
            ))
        }

        // ==========================================
        // 4. PDF (PDFKit Engine)
        // ==========================================
        caps.append(ConversionCapability(
            id: "pdf_compress",
            displayName: "Compress PDF",
            category: .pdf,
            actionCategory: .compress,
            sourceFormatID: "pdf",
            targetFormatID: "pdf",
            requiredEngineID: "com.shiftkit.engine.pdfkit",
            isImplemented: true
        ))

        caps.append(ConversionCapability(
            id: "pdf_to_images",
            displayName: "Render to Images",
            category: .pdf,
            actionCategory: .convert,
            sourceFormatID: "pdf",
            targetFormatID: "png",
            requiredEngineID: "com.shiftkit.engine.pdfkit",
            isImplemented: true
        ))

        caps.append(ConversionCapability(
            id: "pdf_merge",
            displayName: "Merge PDF Documents",
            category: .pdf,
            actionCategory: .merge,
            sourceFormatID: "pdf",
            targetFormatID: "pdf",
            requiredEngineID: "com.shiftkit.engine.pdfkit",
            isImplemented: true
        ))

        // ==========================================
        // 5-8. PLANNED CAPABILITIES (Documents, Structured Data, Archives)
        // (Marked isImplemented: false so they are NOT advertised as ready)
        // ==========================================
        caps.append(ConversionCapability(
            id: "doc_to_pdf",
            displayName: "Document to PDF",
            category: .document,
            actionCategory: .convert,
            sourceFormatID: "docx",
            targetFormatID: "pdf",
            requiredEngineID: "com.shiftkit.engine.pandoc",
            isImplemented: false
        ))

        caps.append(ConversionCapability(
            id: "csv_to_json",
            displayName: "CSV Table to JSON",
            category: .structuredData,
            actionCategory: .convert,
            sourceFormatID: "csv",
            targetFormatID: "json",
            requiredEngineID: "com.shiftkit.engine.data",
            isImplemented: false
        ))

        caps.append(ConversionCapability(
            id: "zip_extract",
            displayName: "Extract Archive",
            category: .archive,
            actionCategory: .extract,
            sourceFormatID: "zip",
            targetFormatID: "zip",
            requiredEngineID: "com.shiftkit.engine.archive",
            isImplemented: false
        ))

        return caps
    }
}
