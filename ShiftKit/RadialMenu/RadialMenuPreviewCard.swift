import SwiftUI

public struct RadialMenuPreviewCard: View {
    @State private var selectedSampleIndex: Int = 0
    @State private var isShiftActive: Bool = false
    @State private var selectedActionNotice: String?

    private let sampleFiles: [InspectedFile] = [
        InspectedFile(
            url: URL(fileURLWithPath: "/Users/demo/Pictures/product-shot.png"),
            fileType: .image(.png),
            metadata: FileMetadata(fileSize: 3_420_100, fileExtension: "png", pixelWidth: 2048, pixelHeight: 1536)
        ),
        InspectedFile(
            url: URL(fileURLWithPath: "/Users/demo/Movies/feature-preview.mp4"),
            fileType: .video(.mp4),
            metadata: FileMetadata(fileSize: 48_600_000, fileExtension: "mp4", pixelWidth: 1920, pixelHeight: 1080, durationSeconds: 42.0)
        ),
        InspectedFile(
            url: URL(fileURLWithPath: "/Users/demo/Music/voice-note.wav"),
            fileType: .audio(.wav),
            metadata: FileMetadata(fileSize: 12_800_000, fileExtension: "wav", durationSeconds: 78.5)
        ),
        InspectedFile(
            url: URL(fileURLWithPath: "/Users/demo/Documents/annual-report.pdf"),
            fileType: .pdf,
            metadata: FileMetadata(fileSize: 4_200_000, fileExtension: "pdf", pageCount: 16)
        )
    ]

    private let registry = ConversionRegistry()
    public let onActionTriggered: ((InspectedFile, ConversionAction) -> Void)?

    public init(onActionTriggered: ((InspectedFile, ConversionAction) -> Void)? = nil) {
        self.onActionTriggered = onActionTriggered
    }

    public var body: some View {
        ShiftKitCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                // Section Title & Selector
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Interactive Radial Menu Preview")
                            .font(ShiftKitTypography.headline)
                            .foregroundColor(ShiftKitColors.charcoalBrown)
                        Text("Test how holding Shift while dragging dynamically configures available operations")
                            .font(ShiftKitTypography.caption)
                            .foregroundColor(ShiftKitColors.textMuted)
                    }

                    Spacer()

                    // Sample file selector tabs
                    HStack(spacing: 4) {
                        ForEach(0..<sampleFiles.count, id: \.self) { idx in
                            let sample = sampleFiles[idx]
                            Button {
                                selectedSampleIndex = idx
                                selectedActionNotice = nil
                            } label: {
                                Image(systemName: sample.fileType.systemIcon)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(selectedSampleIndex == idx ? ShiftKitColors.charcoalBrown : ShiftKitColors.textMuted)
                                    .frame(width: 28, height: 26)
                                    .background(selectedSampleIndex == idx ? ShiftKitColors.softCream : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(selectedSampleIndex == idx ? ShiftKitColors.sandBeige : Color.clear, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .help("Preview with \(sample.fileName)")
                        }
                    }
                    .padding(3)
                    .background(ShiftKitColors.warmIvory)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ShiftKitColors.borderSubtle, lineWidth: 1)
                    )
                }

                // Interactive Demo Canvas
                let currentFile = sampleFiles[selectedSampleIndex]
                let actions = registry.actions(for: currentFile.fileType)

                ZStack {
                    // Canvas textured background
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(ShiftKitColors.warmIvory)
                        .frame(maxWidth: .infinity)
                        .frame(height: 290)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(ShiftKitColors.sandBeige, lineWidth: 1)
                        )

                    // Centered Radial Menu
                    RadialMenuView(
                        file: currentFile,
                        actions: actions,
                        onSelectAction: { action in
                            selectedActionNotice = "Triggered: \(action.title) on \(currentFile.fileName)"
                            onActionTriggered?(currentFile, action)
                        },
                        onDismiss: {}
                    )

                    // Toast notice overlay if triggered
                    if let notice = selectedActionNotice {
                        VStack {
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(ShiftKitColors.deepOlive)
                                Text(notice)
                                    .font(ShiftKitTypography.captionBold)
                                    .foregroundColor(ShiftKitColors.charcoalBrown)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(ShiftKitColors.surface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(ShiftKitColors.sandBeige, lineWidth: 1)
                            )
                            .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.08), radius: 6, x: 0, y: 2)
                            .padding(.bottom, 10)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                // Interaction Guide Footer
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(ShiftKitColors.deepOlive)
                        Text("Hover slices to preview target action • Click to trigger operation")
                            .font(ShiftKitTypography.caption)
                            .foregroundColor(ShiftKitColors.textSecondary)
                    }

                    Spacer()

                    ShiftKitPill(
                        "\(actions.count) Operations Available",
                        icon: "circle.grid.cross",
                        tint: ShiftKitColors.deepOlive,
                        background: ShiftKitColors.softCream
                    )
                }
            }
        }
    }
}
