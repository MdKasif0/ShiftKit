import SwiftUI
import UniformTypeIdentifiers

public struct DropZoneView: View {
    @Binding var inspectedFile: InspectedFile?
    public let onFileDropped: (URL) -> Void
    public let onSelectAction: (ConversionAction) -> Void

    @State private var isTargeted: Bool = false
    @State private var isShiftHeld: Bool = false

    public init(
        inspectedFile: Binding<InspectedFile?>,
        onFileDropped: @escaping (URL) -> Void,
        onSelectAction: @escaping (ConversionAction) -> Void
    ) {
        self._inspectedFile = inspectedFile
        self.onFileDropped = onFileDropped
        self.onSelectAction = onSelectAction
    }

    public var body: some View {
        ShiftKitCard(padding: 0) {
            ZStack {
                // Dashed border zone
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isTargeted ? ShiftKitColors.softTerracotta : ShiftKitColors.sandBeige,
                        style: StrokeStyle(lineWidth: isTargeted ? 2 : 1.5, dash: [6, 4])
                    )
                    .background(
                        isTargeted ? ShiftKitColors.warmPeach.opacity(0.25) : ShiftKitColors.surface
                    )

                if let file = inspectedFile {
                    // File inspected state with actions ready
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: file.fileType.systemIcon)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(ShiftKitColors.deepOlive)
                                .frame(width: 44, height: 44)
                                .background(ShiftKitColors.softCream)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(file.fileName)
                                    .font(ShiftKitTypography.headline)
                                    .foregroundColor(ShiftKitColors.charcoalBrown)
                                    .lineLimit(1)

                                HStack(spacing: 8) {
                                    Text(file.metadata.formattedSize)
                                        .font(ShiftKitTypography.code)
                                    if let dims = file.metadata.dimensionsDescription {
                                        Text("•")
                                        Text(dims).font(ShiftKitTypography.caption)
                                    }
                                    if let dur = file.metadata.durationDescription {
                                        Text("•")
                                        Text(dur).font(ShiftKitTypography.caption)
                                    }
                                    if let pages = file.metadata.pageCount {
                                        Text("•")
                                        Text("\(pages) pages").font(ShiftKitTypography.caption)
                                    }
                                }
                                .foregroundColor(ShiftKitColors.textMuted)
                            }

                            Spacer()

                            Button {
                                inspectedFile = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(ShiftKitColors.sandBeige)
                            }
                            .buttonStyle(.plain)
                        }

                        // Quick action bar for the dropped file
                        let registry = ConversionRegistry()
                        let actions = registry.actions(for: file.fileType)

                        HStack(spacing: 8) {
                            ForEach(actions.prefix(4), id: \.id) { action in
                                Button {
                                    onSelectAction(action)
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: action.systemIcon)
                                            .font(.system(size: 11, weight: .semibold))
                                        Text(action.title)
                                    }
                                }
                                .buttonStyle(ShiftKitPrimaryButtonStyle())
                            }
                        }
                    }
                    .padding(18)

                } else {
                    // Empty drop target state
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(ShiftKitColors.softCream)
                                .frame(width: 50, height: 50)

                            Image(systemName: isTargeted ? "arrow.down.circle.fill" : "plus.viewfinder")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(isTargeted ? ShiftKitColors.softTerracotta : ShiftKitColors.deepOlive)
                        }

                        VStack(spacing: 3) {
                            Text(isTargeted ? "Drop file to open radial actions" : "Drag & Drop File Here")
                                .font(ShiftKitTypography.headline)
                                .foregroundColor(ShiftKitColors.charcoalBrown)

                            Text("Hold Shift while dragging anywhere, or drop a file directly")
                                .font(ShiftKitTypography.caption)
                                .foregroundColor(ShiftKitColors.textMuted)
                        }

                        Button("Browse File...") {
                            chooseFileModal()
                        }
                        .buttonStyle(ShiftKitSecondaryButtonStyle())
                    }
                    .padding(24)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 148)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                guard let provider = providers.first else { return false }
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url else { return }
                    DispatchQueue.main.async {
                        onFileDropped(url)
                    }
                }
                return true
            }
        }
    }

    private func chooseFileModal() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select File"

        if panel.runModal() == .OK, let url = panel.url {
            onFileDropped(url)
        }
    }
}
