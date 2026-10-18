import SwiftUI
import AppKit

public struct SettingsView: View {
    @Bindable var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var isAccessibilityGranted: Bool = InteractionPermissionManager.shared.isAccessibilityGranted

    public init(settings: SettingsStore) {
        self.settings = settings
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ShiftKitColors.deepOlive)
                    Text("ShiftKit Preferences")
                        .font(ShiftKitTypography.title)
                        .foregroundColor(ShiftKitColors.charcoalBrown)
                }

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(ShiftKitSecondaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(ShiftKitColors.surfaceSecondary)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(ShiftKitColors.border),
                alignment: .bottom
            )

            // Settings Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Global Interaction & Permissions Group
                    ShiftKitCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Global Finder Drag Detection")
                                    .font(ShiftKitTypography.headline)
                                    .foregroundColor(ShiftKitColors.charcoalBrown)

                                Spacer()

                                if isAccessibilityGranted {
                                    ShiftKitPill("Active", icon: "checkmark.shield.fill", tint: ShiftKitColors.deepOlive, background: ShiftKitColors.mutedSage.opacity(0.3))
                                } else {
                                    ShiftKitPill("Optional", icon: "exclamationmark.shield", tint: ShiftKitColors.softTerracotta, background: ShiftKitColors.warmPeach.opacity(0.4))
                                }
                            }

                            Text("ShiftKit uses macOS Accessibility permissions solely to detect when you hold Shift while dragging files inside Finder or on your Desktop.")
                                .font(ShiftKitTypography.caption)
                                .foregroundColor(ShiftKitColors.textMuted)

                            if !isAccessibilityGranted {
                                HStack {
                                    Button("Grant Accessibility in System Settings...") {
                                        InteractionPermissionManager.shared.openAccessibilitySettings()
                                    }
                                    .buttonStyle(ShiftKitPrimaryButtonStyle())

                                    Button("Check Status") {
                                        isAccessibilityGranted = InteractionPermissionManager.shared.checkPermission()
                                    }
                                    .buttonStyle(ShiftKitSecondaryButtonStyle())
                                }
                            }

                            Divider().overlay(ShiftKitColors.borderSubtle)

                            // Fallback shortcuts information
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Global Shortcut Fallback:")
                                        .font(ShiftKitTypography.subheadline)
                                        .foregroundColor(ShiftKitColors.charcoalBrown)

                                    Spacer()

                                    ShiftKitPill("⌥⇧S", icon: "keyboard", tint: ShiftKitColors.charcoalBrown, background: ShiftKitColors.softCream)
                                }

                                Text("Press Option + Shift + S anywhere to summon the radial drop target at your mouse cursor without requiring full system permissions.")
                                    .font(ShiftKitTypography.caption)
                                    .foregroundColor(ShiftKitColors.textMuted)
                            }
                        }
                    }

                    // Output Folder Group
                    ShiftKitCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Output Location")
                                .font(ShiftKitTypography.headline)
                                .foregroundColor(ShiftKitColors.charcoalBrown)

                            HStack {
                                Text(settings.outputDirectoryPath)
                                    .font(ShiftKitTypography.code)
                                    .foregroundColor(ShiftKitColors.charcoalBrown)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(ShiftKitColors.softCream)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(ShiftKitColors.border, lineWidth: 1)
                                    )

                                Button("Choose...") {
                                    selectOutputFolder()
                                }
                                .buttonStyle(ShiftKitSecondaryButtonStyle())
                            }

                            Toggle("Reveal processed file in Finder automatically", isOn: $settings.revealInFinderOnCompletion)
                                .font(ShiftKitTypography.body)
                                .foregroundColor(ShiftKitColors.charcoalBrown)
                                .toggleStyle(CheckboxToggleStyle())

                            Toggle("Preserve original files (never overwrite source)", isOn: $settings.keepOriginalFiles)
                                .font(ShiftKitTypography.body)
                                .foregroundColor(ShiftKitColors.charcoalBrown)
                                .toggleStyle(CheckboxToggleStyle())
                        }
                    }

                    // Local Engines Group
                    ShiftKitCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Local Conversion Engines")
                                    .font(ShiftKitTypography.headline)
                                    .foregroundColor(ShiftKitColors.charcoalBrown)

                                Spacer()

                                LocalProcessingBadge()
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("FFmpeg Engine Status:")
                                        .font(ShiftKitTypography.body)
                                        .foregroundColor(ShiftKitColors.charcoalBrown)
                                    Spacer()
                                    if FFmpegEngine.isAvailable {
                                        ShiftKitPill("Available Locally", icon: "checkmark.circle.fill", tint: ShiftKitColors.deepOlive, background: ShiftKitColors.mutedSage.opacity(0.3))
                                    } else {
                                        ShiftKitPill("Optional CLI Not Found", icon: "exclamationmark.triangle", tint: ShiftKitColors.softTerracotta, background: ShiftKitColors.warmPeach.opacity(0.4))
                                    }
                                }

                                Text("Used for animated GIF generation and advanced media transcoding. If not installed via Homebrew (`brew install ffmpeg`), native AVFoundation is used automatically.")
                                    .font(ShiftKitTypography.caption)
                                    .foregroundColor(ShiftKitColors.textMuted)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 520, height: 500)
        .background(ShiftKitColors.background)
        .preferredColorScheme(.light)
        .onAppear {
            isAccessibilityGranted = InteractionPermissionManager.shared.checkPermission()
        }
    }

    private func selectOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Output Folder"

        if panel.runModal() == .OK, let selectedURL = panel.url {
            settings.outputDirectoryPath = selectedURL.path
        }
    }
}
