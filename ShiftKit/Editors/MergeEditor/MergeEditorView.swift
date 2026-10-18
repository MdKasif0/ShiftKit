import SwiftUI
import AppKit
import PDFKit

public enum MergeWorkflowType: String, CaseIterable, Identifiable, Sendable {
    case pdf = "PDF Documents"
    case imagesToPDF = "Images to PDF"
    case audio = "Audio Tracks"
    case video = "Video Clips"
    case incompatible = "Incompatible Files"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .pdf: return "doc.on.doc"
        case .imagesToPDF: return "photo.on.rectangle"
        case .audio: return "waveform"
        case .video: return "film.stack"
        case .incompatible: return "exclamationmark.triangle"
        }
    }
}

public struct MergeItem: Identifiable, Hashable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let formattedSize: String
    public let fileType: FileType
    public var detailText: String
    public var thumbnail: NSImage?

    public init(url: URL, fileType: FileType) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.fileType = fileType

        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        self.formattedSize = DeveloperUtilities.formatFileSize(size)

        switch fileType {
        case .pdf:
            if let doc = PDFDocument(url: url) {
                self.detailText = "\(doc.pageCount) pages"
                self.thumbnail = doc.page(at: 0)?.thumbnail(of: CGSize(width: 80, height: 100), for: .mediaBox)
            } else {
                self.detailText = "PDF"
            }
        case .image:
            if let img = NSImage(contentsOf: url) {
                self.detailText = "\(Int(img.size.width)) × \(Int(img.size.height)) px"
                self.thumbnail = img
            } else {
                self.detailText = "Image"
            }
        case .audio:
            self.detailText = "Audio Track"
        case .video:
            self.detailText = "Video Clip"
        default:
            self.detailText = url.pathExtension.uppercased()
        }
    }
}

public struct MergeEditorView: View {
    @State private var items: [MergeItem]
    @State private var outputName: String = "Merged_Document"
    @State private var addWatermark: Bool = false
    @State private var watermarkText: String = "CONFIDENTIAL"
    @State private var targetFormatExt: String = "pdf"

    public let onMerge: @Sendable ([URL], MergeWorkflowType, [String: String]) -> Void
    public let onCancel: @Sendable () -> Void

    public init(
        initialURLs: [URL],
        onMerge: @Sendable @escaping ([URL], MergeWorkflowType, [String: String]) -> Void,
        onCancel: @Sendable @escaping () -> Void
    ) {
        let detector = FileTypeDetector.shared
        let inspectedItems = initialURLs.map { url in
            MergeItem(url: url, fileType: detector.detect(for: url))
        }
        _items = State(initialValue: inspectedItems)
        self.onMerge = onMerge
        self.onCancel = onCancel
    }

    private var detectedWorkflow: MergeWorkflowType {
        guard !items.isEmpty else { return .incompatible }

        let allPDF = items.allSatisfy { item in
            if case .pdf = item.fileType { return true }
            return item.url.pathExtension.lowercased() == "pdf"
        }
        if allPDF { return .pdf }

        let allImages = items.allSatisfy { item in
            if case .image = item.fileType { return true }
            let ext = item.url.pathExtension.lowercased()
            return ["png", "jpg", "jpeg", "webp", "heic", "tiff"].contains(ext)
        }
        if allImages { return .imagesToPDF }

        let allAudio = items.allSatisfy { item in
            if case .audio = item.fileType { return true }
            let ext = item.url.pathExtension.lowercased()
            return ["mp3", "wav", "m4a", "flac", "aac", "ogg"].contains(ext)
        }
        if allAudio { return .audio }

        let allVideo = items.allSatisfy { item in
            if case .video = item.fileType { return true }
            let ext = item.url.pathExtension.lowercased()
            return ["mp4", "mov", "mkv", "webm", "avi"].contains(ext)
        }
        if allVideo { return .video }

        return .incompatible
    }

    private var isValid: Bool {
        if detectedWorkflow == .incompatible { return false }
        if detectedWorkflow == .imagesToPDF { return items.count >= 1 }
        return items.count >= 2
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerView

            Divider()
                .background(Color(hex: "#E5D8C7"))

            // Main Content: Reorderable Item List
            ScrollView {
                VStack(spacing: 12) {
                    if detectedWorkflow == .incompatible {
                        incompatibleWarningBanner
                    }

                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        itemRow(item: item, index: index)
                    }

                    addMoreFilesButton
                }
                .padding(20)
            }
            .background(Color(hex: "#FAF8F3"))

            Divider()
                .background(Color(hex: "#E5D8C7"))

            // Bottom Options & Action Bar
            bottomBarView
        }
        .frame(minWidth: 540, minHeight: 460)
        .background(Color(hex: "#FAF8F3"))
        .onAppear {
            updateDefaultOutputName()
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: detectedWorkflow.systemIcon)
                        .foregroundColor(Color(hex: "#D98768"))
                        .font(.system(size: 18, weight: .semibold))
                    Text("Merge & Combine Files")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#34312D"))
                }
                Text("Reorder files before combining. Output will follow this exact sequence.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#465343"))
            }

            Spacer()

            // Workflow badge
            Text(detectedWorkflow.rawValue)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: "#F3EEE4"))
                .foregroundColor(Color(hex: "#465343"))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: "#E5D8C7"), lineWidth: 1)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(hex: "#FAF8F3"))
    }

    // MARK: - Incompatible Banner
    private var incompatibleWarningBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color(hex: "#D98768"))
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text("Incompatible File Types")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#34312D"))
                Text("Merge requires items of the same type (e.g. all PDFs, all audio tracks, all videos, or images). Remove mismatched items to proceed.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#465343"))
            }
            Spacer()
        }
        .padding(12)
        .background(Color(hex: "#F5D5C2").opacity(0.4))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "#D98768").opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Item Row
    private func itemRow(item: MergeItem, index: Int) -> some View {
        HStack(spacing: 14) {
            // Sequence Number Badge
            Text("\(index + 1)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#465343"))
                .frame(width: 26, height: 26)
                .background(Color(hex: "#F3EEE4"))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(hex: "#E5D8C7"), lineWidth: 1))

            // Thumbnail or Icon
            if let thumb = item.thumbnail {
                Image(nsImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                    .cornerRadius(4)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "#E5D8C7"), lineWidth: 0.5))
            } else {
                Image(systemName: item.fileType.systemIcon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#D98768"))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "#F3EEE4"))
                    .cornerRadius(4)
            }

            // File Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#34312D"))
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(item.detailText)
                    Text("•")
                    Text(item.formattedSize)
                }
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#465343").opacity(0.8))
            }

            Spacer()

            // Order Controls: Up & Down
            HStack(spacing: 4) {
                Button(action: { moveItem(from: index, to: index - 1) }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color(hex: "#F3EEE4"))
                .cornerRadius(4)
                .disabled(index == 0)
                .opacity(index == 0 ? 0.3 : 1.0)

                Button(action: { moveItem(from: index, to: index + 1) }) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color(hex: "#F3EEE4"))
                .cornerRadius(4)
                .disabled(index == items.count - 1)
                .opacity(index == items.count - 1 ? 0.3 : 1.0)

                Button(action: { deleteItem(at: index) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#D98768"))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color(hex: "#F3EEE4"))
                .cornerRadius(4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "#E5D8C7"), lineWidth: 1)
        )
    }

    // MARK: - Add More Files Button
    private var addMoreFilesButton: some View {
        Button(action: openAddFilesPanel) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle")
                Text("Add More Files...")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color(hex: "#465343"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(hex: "#F3EEE4").opacity(0.6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundColor(Color(hex: "#E5D8C7"))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Bottom Bar
    private var bottomBarView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text("Output Filename:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#34312D"))

                TextField("Filename", text: $outputName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 220)

                Text(".\(targetFormatExt)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#465343"))

                Spacer()

                if detectedWorkflow == .pdf || detectedWorkflow == .imagesToPDF {
                    Toggle("Add Watermark", isOn: $addWatermark)
                        .toggleStyle(CheckboxToggleStyle())
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#34312D"))
                }
            }

            HStack {
                Text("\(items.count) item\(items.count == 1 ? "" : "s") selected")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#465343"))

                Spacer()

                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#F3EEE4"))
                    .foregroundColor(Color(hex: "#34312D"))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#E5D8C7"), lineWidth: 1))
                    .buttonStyle(PlainButtonStyle())

                Button(action: handleMergeTriggered) {
                    Text(mergeButtonTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)
                        .background(isValid ? Color(hex: "#D98768") : Color(hex: "#E5D8C7"))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!isValid)
            }
        }
        .padding(16)
        .background(Color(hex: "#FAF8F3"))
    }

    private var mergeButtonTitle: String {
        switch detectedWorkflow {
        case .pdf: return "Merge \(items.count) PDFs"
        case .imagesToPDF: return "Create PDF from \(items.count) Images"
        case .audio: return "Join \(items.count) Audio Tracks"
        case .video: return "Join \(items.count) Video Clips"
        case .incompatible: return "Incompatible Files"
        }
    }

    // MARK: - Actions
    private func moveItem(from src: Int, to dst: Int) {
        guard dst >= 0 && dst < items.count else { return }
        let moved = items.remove(at: src)
        items.insert(moved, at: dst)
    }

    private func deleteItem(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        items.remove(at: index)
    }

    private func openAddFilesPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK {
            let detector = FileTypeDetector.shared
            for url in panel.urls {
                let type = detector.detect(for: url)
                items.append(MergeItem(url: url, fileType: type))
            }
            updateDefaultOutputName()
        }
    }

    private func updateDefaultOutputName() {
        switch detectedWorkflow {
        case .pdf:
            targetFormatExt = "pdf"
            outputName = "Merged_Document"
        case .imagesToPDF:
            targetFormatExt = "pdf"
            outputName = "Photo_Collection"
        case .audio:
            targetFormatExt = items.first?.url.pathExtension.lowercased() ?? "mp3"
            outputName = "Joined_Audio"
        case .video:
            targetFormatExt = items.first?.url.pathExtension.lowercased() ?? "mp4"
            outputName = "Joined_Video"
        case .incompatible:
            break
        }
    }

    private func handleMergeTriggered() {
        var options: [String: String] = [
            "outputName": outputName,
            "targetFormat": targetFormatExt
        ]
        if addWatermark {
            options["watermarkText"] = watermarkText
        }
        let urls = items.map { item in item.url }
        onMerge(urls, detectedWorkflow, options)
    }
}
