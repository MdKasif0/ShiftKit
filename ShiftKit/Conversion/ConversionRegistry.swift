import Foundation

// MARK: - Protocol
public protocol ConversionRegistering: Sendable {
    func segments(for fileType: FileType) -> [RadialSegmentItem]
    func actions(for fileType: FileType) -> [ConversionAction]
    func defaultAction(for fileType: FileType) -> ConversionAction?
    func searchableActions(for fileType: FileType, query: String) -> [ConversionAction]
}

// MARK: - Implementation
public final class ConversionRegistry: ConversionRegistering {
    public init() {}

    /// Generates the 8 contextual primary segments for the circular radial action menu.
    public func segments(for fileType: FileType) -> [RadialSegmentItem] {
        let convertActions = makeConvertCatalog(for: fileType)
        let compressActions = makeCompressCatalog(for: fileType)
        let cropTrimActions = makeCropTrimCatalog(for: fileType)
        let mergeActions = makeMergeCatalog(for: fileType)
        let editActions = makeEditCatalog(for: fileType)
        let metadataActions = makeMetadataCatalog(for: fileType)
        let extractActions = makeExtractCatalog(for: fileType)
        let moreActions = makeMoreCatalog(for: fileType)

        // Dynamic Title & Icon for Segment 3 (Crop vs Trim)
        let (cropTrimTitle, cropTrimIcon): (String, String) = {
            switch fileType {
            case .video, .audio:
                return ("Trim", "scissors")
            case .image:
                return ("Crop", "crop")
            case .pdf:
                return ("Crop", "crop")
            default:
                return ("Crop/Trim", "scissors")
            }
        }()

        return [
            // 1. Convert
            RadialSegmentItem(
                id: "seg_convert",
                title: "Convert",
                subtitle: "\(convertActions.count) target formats",
                systemIcon: "arrow.triangle.2.circlepath",
                shortcutKey: "1",
                category: .convert,
                isEnabled: !convertActions.isEmpty,
                subActions: convertActions
            ),

            // 2. Compress
            RadialSegmentItem(
                id: "seg_compress",
                title: "Compress",
                subtitle: "Reduce file weight",
                systemIcon: "arrow.down.forward.and.arrow.up.backward",
                shortcutKey: "2",
                category: .compress,
                isEnabled: !compressActions.isEmpty,
                subActions: compressActions
            ),

            // 3. Crop or Trim (Contextual)
            RadialSegmentItem(
                id: "seg_crop_trim",
                title: cropTrimTitle,
                subtitle: fileType.isMedia ? "Adjust boundaries" : "Adjust margins",
                systemIcon: cropTrimIcon,
                shortcutKey: "3",
                category: .cropOrTrim,
                isEnabled: !cropTrimActions.isEmpty,
                subActions: cropTrimActions
            ),

            // 4. Merge
            RadialSegmentItem(
                id: "seg_merge",
                title: "Merge",
                subtitle: "Combine documents",
                systemIcon: "doc.on.doc",
                shortcutKey: "4",
                category: .merge,
                isEnabled: !mergeActions.isEmpty,
                subActions: mergeActions
            ),

            // 5. Edit
            RadialSegmentItem(
                id: "seg_edit",
                title: "Edit",
                subtitle: "Rotate, flip, adjust",
                systemIcon: "slider.horizontal.3",
                shortcutKey: "5",
                category: .edit,
                isEnabled: !editActions.isEmpty,
                subActions: editActions
            ),

            // 6. Metadata
            RadialSegmentItem(
                id: "seg_metadata",
                title: "Metadata",
                subtitle: "Privacy & EXIF clean",
                systemIcon: "info.circle",
                shortcutKey: "6",
                category: .metadata,
                isEnabled: true,
                subActions: metadataActions
            ),

            // 7. Extract
            RadialSegmentItem(
                id: "seg_extract",
                title: "Extract",
                subtitle: fileType.isMedia ? "Extract audio/stills" : "Extract assets",
                systemIcon: "arrow.up.right.and.arrow.down.left.rectangle",
                shortcutKey: "7",
                category: .extract,
                isEnabled: !extractActions.isEmpty,
                subActions: extractActions
            ),

            // 8. More
            RadialSegmentItem(
                id: "seg_more",
                title: "More",
                subtitle: "Finder & utilities",
                systemIcon: "ellipsis.circle",
                shortcutKey: "8",
                category: .more,
                isEnabled: true,
                subActions: moreActions
            )
        ]
    }

    /// Flattened action list for direct selection and backward compatibility
    public func actions(for fileType: FileType) -> [ConversionAction] {
        var result: [ConversionAction] = []
        for segment in segments(for: fileType) {
            result.append(contentsOf: segment.subActions)
        }
        return result
    }

    public func defaultAction(for fileType: FileType) -> ConversionAction? {
        actions(for: fileType).first
    }

    public func searchableActions(for fileType: FileType, query: String) -> [ConversionAction] {
        let all = actions(for: fileType)
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return all
        }
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        return all.filter { action in
            action.title.lowercased().contains(q) ||
            action.subtitle.lowercased().contains(q) ||
            (action.targetFormat?.lowercased().contains(q) ?? false) ||
            (action.badgeTag?.lowercased().contains(q) ?? false)
        }
    }

    // MARK: - Catalog Builders
    private func makeConvertCatalog(for fileType: FileType) -> [ConversionAction] {
        switch fileType {
        case .image:
            return [
                .imageToPNG,
                .imageToJPEG,
                .imageToWebP,
                .imageToHEIC,
                .imageToTIFF,
                ConversionAction(id: "img_to_gif", title: "To Static GIF", subtitle: "Web 256-color palette", systemIcon: "photo", category: .convert, targetFormat: "gif", badgeTag: "GIF"),
                ConversionAction(id: "img_to_pdf", title: "To Single-Page PDF", subtitle: "Encapsulate image in PDF", systemIcon: "doc.richtext", category: .convert, targetFormat: "pdf", badgeTag: "PDF")
            ]
        case .video:
            return [
                .videoToMP4,
                .videoToGIF,
                ConversionAction(id: "vid_to_mov", title: "To Apple ProRes / QuickTime", subtitle: "Native MOV container", systemIcon: "film", category: .convert, targetFormat: "mov", badgeTag: "MOV"),
                ConversionAction(id: "vid_to_webm", title: "To WebM (VP9)", subtitle: "Open HTML5 web video", systemIcon: "globe", category: .convert, targetFormat: "webm", badgeTag: "VP9")
            ]
        case .audio:
            return [
                .audioToMP3,
                .audioToM4A,
                ConversionAction(id: "audio_to_wav", title: "To WAV (PCM)", subtitle: "Uncompressed 16-bit 44.1kHz", systemIcon: "waveform", category: .convert, targetFormat: "wav", badgeTag: "Lossless"),
                ConversionAction(id: "audio_to_flac", title: "To FLAC", subtitle: "Free Lossless Audio Codec", systemIcon: "waveform.badge.plus", category: .convert, targetFormat: "flac", badgeTag: "Lossless")
            ]
        case .pdf:
            return [
                .pdfToImages,
                ConversionAction(id: "pdf_to_jpeg", title: "Pages to JPEG", subtitle: "Render pages as high-res JPEGs", systemIcon: "photo", category: .convert, targetFormat: "jpg", badgeTag: "JPEG"),
                ConversionAction(id: "pdf_to_tiff", title: "Pages to TIFF", subtitle: "Archival 300DPI TIFFs", systemIcon: "printer", category: .convert, targetFormat: "tiff", badgeTag: "Archival")
            ]
        default:
            return [
                ConversionAction(id: "doc_to_pdf", title: "To PDF Document", subtitle: "Export text to printable PDF", systemIcon: "doc.richtext", category: .convert, targetFormat: "pdf", badgeTag: "PDF")
            ]
        }
    }

    private func makeCompressCatalog(for fileType: FileType) -> [ConversionAction] {
        switch fileType {
        case .image:
            return [
                .imageCompress,
                ConversionAction(id: "img_compress_max", title: "Maximum Compression", subtitle: "High compression ~70% reduction", systemIcon: "arrow.down.forward.and.arrow.up.backward", category: .compress, badgeTag: "Max (~70%)", options: ["quality": "0.50"]),
                ConversionAction(id: "img_compress_light", title: "Light Lossless Optimization", subtitle: "Strips bloat without visual change", systemIcon: "arrow.down.forward.and.arrow.up.backward", category: .compress, badgeTag: "Light (~20%)", options: ["quality": "0.90"])
            ]
        case .video:
            return [
                .videoCompress,
                ConversionAction(id: "vid_compress_720p", title: "Compress 720p Mobile", subtitle: "Balanced bitrate for mobile sharing", systemIcon: "iphone", category: .compress, badgeTag: "720p"),
                ConversionAction(id: "vid_compress_480p", title: "Compress 480p Compact", subtitle: "Ultra lightweight archive", systemIcon: "arrow.down.right.and.arrow.up.left", category: .compress, badgeTag: "480p")
            ]
        case .audio:
            return [
                .audioCompress,
                ConversionAction(id: "audio_compress_voice", title: "Compress for Voice", subtitle: "Mono 64kbps speech optimization", systemIcon: "mic", category: .compress, badgeTag: "64kbps")
            ]
        case .pdf:
            return [
                .pdfCompress,
                ConversionAction(id: "pdf_compress_grayscale", title: "Compress & Grayscale", subtitle: "Convert images to monochrome", systemIcon: "circle.lefthalf.filled", category: .compress, badgeTag: "Monochrome")
            ]
        default:
            return []
        }
    }

    private func makeCropTrimCatalog(for fileType: FileType) -> [ConversionAction] {
        switch fileType {
        case .image:
            return [
                .imageCropSquare,
                ConversionAction(id: "img_crop_16_9", title: "Crop 16:9 Landscape", subtitle: "Standard presentation ratio", systemIcon: "rectangle.ratio.16.to.9", category: .cropOrTrim, badgeTag: "16:9", options: ["aspect": "16:9"]),
                ConversionAction(id: "img_crop_4_3", title: "Crop 4:3 Photo", subtitle: "Classic photography ratio", systemIcon: "rectangle.ratio.4.to.3", category: .cropOrTrim, badgeTag: "4:3", options: ["aspect": "4:3"]),
                ConversionAction(id: "img_crop_9_16", title: "Crop 9:16 Story", subtitle: "Vertical mobile format", systemIcon: "iphone", category: .cropOrTrim, badgeTag: "9:16", options: ["aspect": "9:16"])
            ]
        case .video:
            return [
                .videoTrim,
                ConversionAction(id: "vid_trim_first_30", title: "Trim First 30s", subtitle: "Extract opening 30 seconds", systemIcon: "clock", category: .cropOrTrim, badgeTag: "First 30s", options: ["duration": "30"]),
                ConversionAction(id: "vid_trim_first_60", title: "Trim First 60s", subtitle: "Extract opening 60 seconds", systemIcon: "clock.fill", category: .cropOrTrim, badgeTag: "First 60s", options: ["duration": "60"])
            ]
        case .audio:
            return [
                ConversionAction(id: "audio_trim_30", title: "Trim to 30s Sample", subtitle: "Extract opening preview hook", systemIcon: "scissors", category: .cropOrTrim, badgeTag: "30s Preview")
            ]
        default:
            return []
        }
    }

    private func makeMergeCatalog(for fileType: FileType) -> [ConversionAction] {
        switch fileType {
        case .pdf:
            return [
                .pdfMerge,
                ConversionAction(id: "pdf_append_blank", title: "Append Blank Note Page", subtitle: "Insert white margin page", systemIcon: "doc.badge.plus", category: .merge, badgeTag: "Blank Page")
            ]
        case .image:
            return [
                ConversionAction(id: "img_combine_pdf", title: "Combine into Multi-Page PDF", subtitle: "Collate with other photos", systemIcon: "doc.on.doc", category: .merge, targetFormat: "pdf", badgeTag: "Multi-PDF"),
                ConversionAction(id: "img_stitch_vertical", title: "Stitch Vertically", subtitle: "Combine top to bottom", systemIcon: "rectangle.split.1x2", category: .merge, badgeTag: "Vertical")
            ]
        default:
            return []
        }
    }

    private func makeEditCatalog(for fileType: FileType) -> [ConversionAction] {
        switch fileType {
        case .image:
            return [
                ConversionAction(id: "img_rotate_cw", title: "Rotate 90° Clockwise", subtitle: "Quarter turn right", systemIcon: "rotate.right", category: .edit, badgeTag: "90° CW"),
                ConversionAction(id: "img_rotate_ccw", title: "Rotate 90° Counter-CW", subtitle: "Quarter turn left", systemIcon: "rotate.left", category: .edit, badgeTag: "90° CCW"),
                ConversionAction(id: "img_flip_horizontal", title: "Flip Horizontal", subtitle: "Mirror image left to right", systemIcon: "arrow.left.and.right.righttriangle.left.righttriangle.right", category: .edit, badgeTag: "Mirror"),
                ConversionAction(id: "img_grayscale", title: "Apply Grayscale", subtitle: "Convert to clean monochrome", systemIcon: "circle.lefthalf.filled", category: .edit, badgeTag: "B&W")
            ]
        case .video:
            return [
                ConversionAction(id: "vid_mute", title: "Mute Audio Track", subtitle: "Strip audio track completely", systemIcon: "speaker.slash", category: .edit, badgeTag: "Mute"),
                ConversionAction(id: "vid_speed_2x", title: "Speed Up 2.0x", subtitle: "Double playback rate", systemIcon: "forward.fill", category: .edit, badgeTag: "2x Fast")
            ]
        case .audio:
            return [
                ConversionAction(id: "audio_normalize", title: "Normalize Volume", subtitle: "Balance loudness to standard LUFS", systemIcon: "waveform.badge.magnifyingglass", category: .edit, badgeTag: "Normalize")
            ]
        default:
            return []
        }
    }

    private func makeMetadataCatalog(for fileType: FileType) -> [ConversionAction] {
        return [
            .imageStripMetadata,
            ConversionAction(id: "meta_clean_gps", title: "Remove GPS Coordinates", subtitle: "Strip latitude/longitude only", systemIcon: "location.slash", category: .metadata, badgeTag: "Location"),
            ConversionAction(id: "meta_inspect_json", title: "Export Metadata (JSON)", subtitle: "Dump attributes to JSON file", systemIcon: "curlybraces", category: .metadata, targetFormat: "json", badgeTag: "JSON")
        ]
    }

    private func makeExtractCatalog(for fileType: FileType) -> [ConversionAction] {
        switch fileType {
        case .video:
            return [
                .videoExtractAudio,
                ConversionAction(id: "vid_extract_aac", title: "Extract M4A (AAC)", subtitle: "Lossless Apple audio stream", systemIcon: "music.note", category: .extract, targetFormat: "m4a", badgeTag: "AAC"),
                ConversionAction(id: "vid_extract_first_frame", title: "Extract Poster Frame", subtitle: "Save opening frame as PNG", systemIcon: "photo", category: .extract, targetFormat: "png", badgeTag: "Thumbnail")
            ]
        case .pdf:
            return [
                .pdfToImages,
                ConversionAction(id: "pdf_extract_first", title: "Extract Cover Page", subtitle: "Save page 1 as high-res PNG", systemIcon: "doc.viewfinder", category: .extract, targetFormat: "png", badgeTag: "Page 1")
            ]
        default:
            return []
        }
    }

    private func makeMoreCatalog(for fileType: FileType) -> [ConversionAction] {
        return [
            ConversionAction(id: "more_reveal", title: "Reveal in Finder", subtitle: "Locate original file on disk", systemIcon: "folder", category: .more, badgeTag: "Finder"),
            ConversionAction(id: "more_duplicate", title: "Quick Duplicate", subtitle: "Create instant copy beside original", systemIcon: "plus.square.on.square", category: .more, badgeTag: "Copy"),
            ConversionAction(id: "more_copy_path", title: "Copy File Path", subtitle: "Copy absolute path to clipboard", systemIcon: "doc.on.clipboard", category: .more, badgeTag: "Clipboard")
        ]
    }
}
