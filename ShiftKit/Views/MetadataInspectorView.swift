import SwiftUI
import AppKit

public struct MetadataInspectorView: View {
    public let inspectedFile: InspectedFile
    public let onApplyChanges: @Sendable (InspectedFile, [String: String], Bool) -> Void
    public let onClose: @Sendable () -> Void

    @State private var pdfTitle: String = ""
    @State private var pdfAuthor: String = ""
    @State private var pdfSubject: String = ""
    @State private var pdfKeywords: String = ""
    @State private var pdfCreator: String = ""

    @State private var mediaTitle: String = ""
    @State private var mediaArtist: String = ""
    @State private var mediaAlbum: String = ""
    @State private var mediaYear: String = ""
    @State private var mediaGenre: String = ""

    @State private var pdfInfo: PDFMetadataInfo? = nil
    @State private var copiedHash: Bool = false
    @State private var calculatedSHA256: String = "Calculating..."

    public init(
        inspectedFile: InspectedFile,
        onApplyChanges: @Sendable @escaping (InspectedFile, [String: String], Bool) -> Void,
        onClose: @Sendable @escaping () -> Void
    ) {
        self.inspectedFile = inspectedFile
        self.onApplyChanges = onApplyChanges
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            Divider().background(Color(hex: "#E5D8C7"))

            ScrollView {
                VStack(spacing: 16) {
                    // Educational Notice
                    safetyNoticeBanner

                    // General File Information
                    generalSection

                    // Format-Specific Inspector & Editor
                    if case .pdf = inspectedFile.fileType {
                        pdfInspectorSection
                    } else if case .image = inspectedFile.fileType {
                        imageInspectorSection
                    } else if case .audio = inspectedFile.fileType {
                        audioInspectorSection
                    } else if case .video = inspectedFile.fileType {
                        videoInspectorSection
                    }
                }
                .padding(20)
            }
            .background(Color(hex: "#FAF8F3"))

            Divider().background(Color(hex: "#E5D8C7"))

            // Footer
            footerBar
        }
        .frame(minWidth: 560, minHeight: 520)
        .background(Color(hex: "#FAF8F3"))
        .onAppear {
            loadMetadata()
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(Color(hex: "#D98768"))
                .font(.system(size: 18, weight: .semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text("Metadata Inspector & Privacy Cleaner")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#34312D"))
                Text(inspectedFile.url.lastPathComponent)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#465343"))
                    .lineLimit(1)
            }
            Spacer()
            Text(inspectedFile.fileType.displayName)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: "#F3EEE4"))
                .foregroundColor(Color(hex: "#465343"))
                .cornerRadius(6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(hex: "#FAF8F3"))
    }

    // MARK: - Safety Notice
    private var safetyNoticeBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundColor(Color(hex: "#465343"))
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text("Non-Destructive Metadata Processing")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#34312D"))
                Text("ShiftKit writes a sanitized copy to your chosen output directory. Your original file remains completely unaltered.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#465343"))
            }
            Spacer()
        }
        .padding(12)
        .background(Color(hex: "#F3EEE4"))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#E5D8C7"), lineWidth: 1))
    }

    // MARK: - General Section
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("General Inspection")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "#34312D"))

            VStack(spacing: 8) {
                infoRow(label: "File Size", value: inspectedFile.metadata.formattedSize)
                infoRow(label: "MIME Type", value: inspectedFile.metadata.mimeType ?? "Unknown")
                infoRow(label: "UTI Identifier", value: inspectedFile.metadata.uti ?? "Unknown")

                HStack {
                    Text("SHA-256")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#465343"))
                        .frame(width: 100, alignment: .leading)
                    Text(calculatedSHA256)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(hex: "#34312D"))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button(action: copySHA256) {
                        Text(copiedHash ? "Copied" : "Copy")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#D98768"))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#E5D8C7"), lineWidth: 1))
        }
    }

    // MARK: - PDF Inspector
    private var pdfInspectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PDF Document Attributes")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#34312D"))
                Spacer()
                Button(action: stripAllMetadataTriggered) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.slash")
                        Text("Strip All Metadata")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#D98768"))
                }
                .buttonStyle(PlainButtonStyle())
            }

            VStack(spacing: 10) {
                if let info = pdfInfo {
                    infoRow(label: "Page Count", value: "\(info.pageCount) pages")
                    infoRow(label: "Dimensions", value: info.pageSizeSummary)
                    infoRow(label: "Encrypted", value: info.isEncrypted ? "Yes" : "No")
                    infoRow(label: "Producer", value: info.producer ?? "Unknown")
                }

                Divider().background(Color(hex: "#E5D8C7"))

                editableRow(label: "Title", text: $pdfTitle)
                editableRow(label: "Author", text: $pdfAuthor)
                editableRow(label: "Subject", text: $pdfSubject)
                editableRow(label: "Keywords", text: $pdfKeywords)
                editableRow(label: "Creator", text: $pdfCreator)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#E5D8C7"), lineWidth: 1))
        }
    }

    // MARK: - Image Inspector
    private var imageInspectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Image EXIF & Camera Data")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#34312D"))
                Spacer()
                Button(action: stripAllMetadataTriggered) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.slash")
                        Text("Clean EXIF / GPS")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#D98768"))
                }
                .buttonStyle(PlainButtonStyle())
            }

            VStack(spacing: 8) {
                if let dims = inspectedFile.metadata.dimensionsDescription {
                    infoRow(label: "Dimensions", value: dims)
                }
                infoRow(label: "Alpha Channel", value: inspectedFile.metadata.hasAlphaChannel ? "Present" : "None")
                if let cs = inspectedFile.metadata.colorSpace {
                    infoRow(label: "Color Space", value: cs)
                }
                infoRow(label: "Format", value: inspectedFile.metadata.detectedFormat?.displayName ?? inspectedFile.fileType.displayName)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#E5D8C7"), lineWidth: 1))
        }
    }

    // MARK: - Audio Inspector
    private var audioInspectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Audio Tags & Properties")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#34312D"))
                Spacer()
                Button(action: stripAllMetadataTriggered) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.slash")
                        Text("Strip Tags")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#D98768"))
                }
                .buttonStyle(PlainButtonStyle())
            }

            VStack(spacing: 10) {
                editableRow(label: "Track Title", text: $mediaTitle)
                editableRow(label: "Artist", text: $mediaArtist)
                editableRow(label: "Album", text: $mediaAlbum)
                editableRow(label: "Year", text: $mediaYear)
                editableRow(label: "Genre", text: $mediaGenre)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#E5D8C7"), lineWidth: 1))
        }
    }

    // MARK: - Video Inspector
    private var videoInspectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Video Stream Properties")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "#34312D"))

            VStack(spacing: 8) {
                if let dims = inspectedFile.metadata.dimensionsDescription {
                    infoRow(label: "Resolution", value: dims)
                }
                if let dur = inspectedFile.metadata.durationSeconds {
                    infoRow(label: "Duration", value: TrimGeometryEngine.formatTimestamp(dur))
                }
                infoRow(label: "Container", value: inspectedFile.url.pathExtension.uppercased())
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#E5D8C7"), lineWidth: 1))
        }
    }

    // MARK: - Footer
    private var footerBar: some View {
        HStack {
            Button("Close", action: onClose)
                .keyboardShortcut(.cancelAction)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(hex: "#F3EEE4"))
                .foregroundColor(Color(hex: "#34312D"))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#E5D8C7"), lineWidth: 1))
                .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: saveChangesTriggered) {
                Text("Save Metadata Changes")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#D98768"))
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Color(hex: "#FAF8F3"))
    }

    // MARK: - Row Helpers
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#465343"))
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#34312D"))
            Spacer()
        }
    }

    private func editableRow(label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#465343"))
                .frame(width: 100, alignment: .leading)
            TextField(label, text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }

    // MARK: - Actions
    private func copySHA256() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(calculatedSHA256, forType: .string)
        copiedHash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            copiedHash = false
        }
    }

    private func loadMetadata() {
        Task.detached {
            let hash = (try? DeveloperUtilities.calculateSHA256(for: inspectedFile.url)) ?? "Unavailable"
            await MainActor.run {
                self.calculatedSHA256 = hash
            }
        }
        if case .pdf = inspectedFile.fileType {
            let engine = PDFKitEngine()
            if let info = try? engine.inspectMetadata(url: inspectedFile.url) {
                self.pdfInfo = info
                self.pdfTitle = info.title ?? ""
                self.pdfAuthor = info.author ?? ""
                self.pdfSubject = info.subject ?? ""
                self.pdfKeywords = info.keywords.joined(separator: ", ")
                self.pdfCreator = info.creator ?? ""
            }
        }
    }

    private func saveChangesTriggered() {
        var options: [String: String] = [:]
        if case .pdf = inspectedFile.fileType {
            options["title"] = pdfTitle
            options["author"] = pdfAuthor
            options["subject"] = pdfSubject
            options["keywords"] = pdfKeywords
            options["creator"] = pdfCreator
        } else if case .audio = inspectedFile.fileType {
            options["title"] = mediaTitle
            options["artist"] = mediaArtist
            options["album"] = mediaAlbum
            options["year"] = mediaYear
            options["genre"] = mediaGenre
        }
        onApplyChanges(inspectedFile, options, false)
    }

    private func stripAllMetadataTriggered() {
        onApplyChanges(inspectedFile, [:], true)
    }
}
