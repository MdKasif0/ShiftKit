import SwiftUI
import AppKit

public struct SettingsView: View {
    @Bindable var settings: SettingsStore
    @State private var selectedTab: SettingsTab = .general
    @State private var isAccessibilityGranted: Bool = false
    @State private var tempCleanedMessage: String?
    @State private var showResetAlert: Bool = false

    public enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case interaction = "Interaction"
        case conversion = "Conversion"
        case output = "Output"
        case privacy = "Privacy"
        case about = "About"

        public var id: String { rawValue }

        public var systemIcon: String {
            switch self {
            case .general: return "gearshape"
            case .interaction: return "hand.tap"
            case .conversion: return "arrow.triangle.2.circlepath"
            case .output: return "folder"
            case .privacy: return "lock.shield"
            case .about: return "info.circle"
            }
        }
    }

    public init(settings: SettingsStore) {
        self.settings = settings
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Sidebar Navigation
            VStack(alignment: .leading, spacing: 6) {
                // Settings Header
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ShiftKitColors.deepOlive)
                    Text("Settings")
                        .font(ShiftKitTypography.headline)
                        .foregroundColor(ShiftKitColors.charcoalBrown)
                }
                .padding(.horizontal, 14)
                .padding(.top, 16)
                .padding(.bottom, 10)

                ForEach(SettingsTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: tab.systemIcon)
                                .font(.system(size: 13, weight: .medium))
                                .frame(width: 18)
                                .foregroundColor(selectedTab == tab ? ShiftKitColors.deepOlive : ShiftKitColors.textSecondary)

                            Text(tab.rawValue)
                                .font(ShiftKitTypography.body)
                                .foregroundColor(selectedTab == tab ? ShiftKitColors.charcoalBrown : ShiftKitColors.textSecondary)

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? ShiftKitColors.surface : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(selectedTab == tab ? ShiftKitColors.border : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(tab.rawValue) Settings")
                }

                Spacer()

                // Reset Button
                Button {
                    showResetAlert = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11))
                        Text("Reset to Defaults")
                            .font(ShiftKitTypography.caption)
                    }
                    .foregroundColor(ShiftKitColors.softTerracotta)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 14)
                .padding(.horizontal, 10)
            }
            .frame(width: 175)
            .background(ShiftKitColors.surfaceSecondary)
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(ShiftKitColors.border),
                alignment: .trailing
            )

            // Content Area
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    switch selectedTab {
                    case .general:
                        generalSection
                    case .interaction:
                        interactionSection
                    case .conversion:
                        conversionSection
                    case .output:
                        outputSection
                    case .privacy:
                        privacySection
                    case .about:
                        aboutSection
                    }
                }
                .padding(22)
            }
            .background(ShiftKitColors.background)
        }
        .frame(width: 660, height: 540)
        .preferredColorScheme(.light)
        .onAppear {
            isAccessibilityGranted = InteractionPermissionManager.shared.checkPermission()
        }
        .alert("Reset Settings?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                settings.resetToDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will restore default conversion options, directories, and preferences.")
        }
    }

    // MARK: - 1. General Section
    @ViewBuilder
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "General Preferences", subtitle: "Application startup, menu bar visibility, and system integration.")

            ShiftKitCard {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Launch ShiftKit automatically at login", isOn: $settings.launchAtLogin)
                        .font(ShiftKitTypography.body)
                        .foregroundColor(ShiftKitColors.charcoalBrown)
                        .toggleStyle(CheckboxToggleStyle())
                        .disabled(!LaunchAtLoginManager.shared.isAvailable)

                    if !LaunchAtLoginManager.shared.isAvailable {
                        Text("Launch at login requires macOS 13.0 or later.")
                            .font(ShiftKitTypography.caption)
                            .foregroundColor(ShiftKitColors.textMuted)
                    }

                    Divider().overlay(ShiftKitColors.borderSubtle)

                    Toggle("Show ShiftKit icon in menu bar", isOn: $settings.showInMenuBar)
                        .font(ShiftKitTypography.body)
                        .foregroundColor(ShiftKitColors.charcoalBrown)
                        .toggleStyle(CheckboxToggleStyle())

                    Toggle("Keep ShiftKit visible in macOS Dock", isOn: $settings.dockIconVisible)
                        .font(ShiftKitTypography.body)
                        .foregroundColor(ShiftKitColors.charcoalBrown)
                        .toggleStyle(CheckboxToggleStyle())
                }
            }

            ShiftKitCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("App Version & Build")
                        .font(ShiftKitTypography.headline)
                        .foregroundColor(ShiftKitColors.charcoalBrown)

                    HStack(spacing: 8) {
                        ShiftKitPill("Version \(settings.appVersion)", icon: "tag", tint: ShiftKitColors.deepOlive, background: ShiftKitColors.mutedSage.opacity(0.3))
                        ShiftKitPill("Build \(settings.buildNumber)", tint: ShiftKitColors.charcoalBrown, background: ShiftKitColors.softCream)
                        Spacer()
                    }

                    Text("ShiftKit operates completely offline on your Mac with local sandbox entitlements.")
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.textMuted)
                }
            }
        }
    }

    // MARK: - 2. Interaction Section
    @ViewBuilder
    private var interactionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Interaction & Shortcuts", subtitle: "Configure activation gestures, radial menu motion, and navigation.")

            // Signature Shift + Drag
            ShiftKitCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Signature Activation: Shift + Drag")
                            .font(ShiftKitTypography.headline)
                            .foregroundColor(ShiftKitColors.charcoalBrown)

                        Spacer()

                        if isAccessibilityGranted {
                            ShiftKitPill("Active", icon: "checkmark.shield.fill", tint: ShiftKitColors.deepOlive, background: ShiftKitColors.mutedSage.opacity(0.3))
                        } else {
                            ShiftKitPill("Permission Required", icon: "exclamationmark.shield", tint: ShiftKitColors.softTerracotta, background: ShiftKitColors.warmPeach.opacity(0.4))
                        }
                    }

                    Text("Hold the Shift key while dragging any file from Finder or your Desktop to instantly reveal the circular radial action menu at your cursor.")
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.textMuted)

                    if !isAccessibilityGranted {
                        HStack(spacing: 10) {
                            Button("Grant Accessibility Access...") {
                                InteractionPermissionManager.shared.openAccessibilitySettings()
                            }
                            .buttonStyle(ShiftKitPrimaryButtonStyle())

                            Button("Verify Status") {
                                isAccessibilityGranted = InteractionPermissionManager.shared.checkPermission()
                            }
                            .buttonStyle(ShiftKitSecondaryButtonStyle())
                        }
                    }
                }
            }

            // Keyboard Shortcut Summon
            ShiftKitCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Global Summon Shortcut")
                            .font(ShiftKitTypography.headline)
                            .foregroundColor(ShiftKitColors.charcoalBrown)

                        Spacer()

                        ShiftKitPill(settings.keyboardShortcutDisplay, icon: "keyboard", tint: ShiftKitColors.charcoalBrown, background: ShiftKitColors.softCream)
                    }

                    Text("Press Option + Shift + S anywhere to summon the radial drop target at your mouse cursor without requiring full system permissions.")
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.textMuted)
                }
            }

            // Animation Style & Keyboard Nav
            ShiftKitCard {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Radial Menu Animation Style")
                            .font(ShiftKitTypography.headline)
                            .foregroundColor(ShiftKitColors.charcoalBrown)

                        Picker("", selection: $settings.radialAnimation) {
                            ForEach(RadialMenuAnimationStyle.allCases) { style in
                                Text(style.displayName).tag(style)
                            }
                        }
                        .labelsHidden()
                    }

                    Divider().overlay(ShiftKitColors.borderSubtle)

                    Toggle("Enable full keyboard navigation (Arrows to select, Enter to run, Esc to close)", isOn: $settings.keyboardNavigationEnabled)
                        .font(ShiftKitTypography.body)
                        .foregroundColor(ShiftKitColors.charcoalBrown)
                        .toggleStyle(CheckboxToggleStyle())
                }
            }

            // Gesture policy notice
            Text("Notice: ShiftKit adheres strictly to macOS security boundaries and uses standard Apple event taps. No unsupported kernel or private system-wide hooks are used.")
                .font(ShiftKitTypography.caption)
                .foregroundColor(ShiftKitColors.textMuted)
        }
    }

    // MARK: - 3. Conversion Section
    @ViewBuilder
    private var conversionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Conversion Pipeline", subtitle: "Tune concurrency limits, media compression, and inspect local processing engines.")

            // Concurrency Limit
            ShiftKitCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Concurrent Processing Limit")
                                .font(ShiftKitTypography.headline)
                                .foregroundColor(ShiftKitColors.charcoalBrown)
                            Text("Limits simultaneous background conversions to prevent CPU or memory exhaustion.")
                                .font(ShiftKitTypography.caption)
                                .foregroundColor(ShiftKitColors.textMuted)
                        }
                        Spacer()
                        ShiftKitPill("\(settings.maxConcurrentJobs) Jobs", tint: ShiftKitColors.deepOlive, background: ShiftKitColors.mutedSage.opacity(0.3))
                    }

                    Stepper("Max Concurrent Jobs: \(settings.maxConcurrentJobs)", value: $settings.maxConcurrentJobs, in: 1...4)
                        .font(ShiftKitTypography.body)
                        .foregroundColor(ShiftKitColors.charcoalBrown)
                }
            }

            // Media Quality Defaults
            ShiftKitCard {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Default Image Compression Quality:")
                                .font(ShiftKitTypography.body)
                                .foregroundColor(ShiftKitColors.charcoalBrown)
                            Spacer()
                            Text("\(Int(settings.defaultImageQuality * 100))%")
                                .font(ShiftKitTypography.code)
                                .foregroundColor(ShiftKitColors.deepOlive)
                        }
                        Slider(value: $settings.defaultImageQuality, in: 0.2...1.0, step: 0.05)
                            .tint(ShiftKitColors.deepOlive)
                    }

                    Divider().overlay(ShiftKitColors.borderSubtle)

                    HStack {
                        Text("Default Audio Bitrate:")
                            .font(ShiftKitTypography.body)
                            .foregroundColor(ShiftKitColors.charcoalBrown)
                        Spacer()
                        Picker("", selection: $settings.defaultAudioBitrateKbps) {
                            Text("128 kbps (Light)").tag(128)
                            Text("192 kbps (Standard)").tag(192)
                            Text("256 kbps (High)").tag(256)
                            Text("320 kbps (Max)").tag(320)
                        }
                        .labelsHidden()
                    }
                }
            }

            // Local Engines Audit
            ShiftKitCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Local Processing Engines")
                            .font(ShiftKitTypography.headline)
                            .foregroundColor(ShiftKitColors.charcoalBrown)
                        Spacer()
                        LocalProcessingBadge()
                    }

                    engineRow(name: "Apple PDFKit & CoreText", desc: "Native vector pagination, PDF merge, split, and text extraction", active: true)
                    engineRow(name: "Apple CoreGraphics & ImageIO", desc: "Hardware-accelerated image conversion and cropping", active: true)
                    engineRow(name: "FFmpeg Media Engine", desc: "Transcoding, video compression, trimming, and audio concat", active: FFmpegEngine.isAvailable)
                    engineRow(name: "LibreOffice Bridge", desc: "Optional external engine for XLSX / PPTX documents", active: DocumentConversionEngine.isLibreOfficeAvailable)
                }
            }
        }
    }

    private func engineRow(name: String, desc: String, active: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: active ? "checkmark.circle.fill" : "exclamationmark.circle")
                .foregroundColor(active ? ShiftKitColors.deepOlive : ShiftKitColors.softTerracotta)
                .font(.system(size: 13))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(ShiftKitTypography.subheadline)
                    .foregroundColor(ShiftKitColors.charcoalBrown)
                Text(desc)
                    .font(ShiftKitTypography.caption)
                    .foregroundColor(ShiftKitColors.textMuted)
            }
            Spacer()
            ShiftKitPill(active ? "Available" : "Optional", tint: active ? ShiftKitColors.deepOlive : ShiftKitColors.softTerracotta, background: active ? ShiftKitColors.mutedSage.opacity(0.3) : ShiftKitColors.warmPeach.opacity(0.3))
        }
    }

    // MARK: - 4. Output Section
    @ViewBuilder
    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Output Destination & Conflicts", subtitle: "Configure where converted files are saved and how duplicates are resolved.")

            // Location Strategy
            ShiftKitCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Save Location Strategy")
                        .font(ShiftKitTypography.headline)
                        .foregroundColor(ShiftKitColors.charcoalBrown)

                    Picker("", selection: $settings.outputLocationPreference) {
                        ForEach(OutputLocationPreference.allCases) { pref in
                            Text(pref.displayName).tag(pref)
                        }
                    }
                    .pickerStyle(.segmented)

                    if settings.outputLocationPreference == .dedicatedFolder {
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
                    }
                }
            }

            // Conflict Resolution
            ShiftKitCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Filename Conflict Behavior")
                        .font(ShiftKitTypography.headline)
                        .foregroundColor(ShiftKitColors.charcoalBrown)

                    Text("When an output file with the same name already exists in the destination folder:")
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.textMuted)

                    Picker("", selection: $settings.filenameConflictResolution) {
                        ForEach(FilenameConflictResolution.allCases) { conflict in
                            Text(conflict.displayName).tag(conflict)
                        }
                    }
                    .labelsHidden()
                }
            }

            // Post-conversion toggles
            ShiftKitCard {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Reveal output file in Finder upon completion", isOn: $settings.revealInFinderOnCompletion)
                        .font(ShiftKitTypography.body)
                        .foregroundColor(ShiftKitColors.charcoalBrown)
                        .toggleStyle(CheckboxToggleStyle())

                    Toggle("Preserve original files (never overwrite or delete source)", isOn: $settings.keepOriginalFiles)
                        .font(ShiftKitTypography.body)
                        .foregroundColor(ShiftKitColors.charcoalBrown)
                        .toggleStyle(CheckboxToggleStyle())

                    Toggle("Play sound on conversion completion", isOn: $settings.playSoundOnCompletion)
                        .font(ShiftKitTypography.body)
                        .foregroundColor(ShiftKitColors.charcoalBrown)
                        .toggleStyle(CheckboxToggleStyle())
                }
            }
        }
    }

    // MARK: - 5. Privacy Section
    @ViewBuilder
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Privacy & Local Safety", subtitle: "Zero network telemetry, strictly local execution, and disk safety.")

            ShiftKitCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(ShiftKitColors.deepOlive)
                            .font(.system(size: 16))
                        Text("100% On-Device Processing")
                            .font(ShiftKitTypography.headline)
                            .foregroundColor(ShiftKitColors.charcoalBrown)
                    }

                    Text("ShiftKit operates without conversion servers, cloud APIs, or internet dependencies. Your documents, photos, audio clips, and videos never leave your Mac.")
                        .font(ShiftKitTypography.body)
                        .foregroundColor(ShiftKitColors.charcoalBrown)

                    Divider().overlay(ShiftKitColors.borderSubtle)

                    Text("• Temporary Files: Created in atomic local sandboxes and immediately cleaned up.")
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.textSecondary)

                    Text("• Active Cancellation: If you cancel an operation, partial output files are erased instantly.")
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.textSecondary)

                    Text("• Diagnostics: ShiftKit does not capture document contents, thumbnails, or metadata in logs.")
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.textSecondary)
                }
            }

            ShiftKitCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Disk Hygiene")
                        .font(ShiftKitTypography.headline)
                        .foregroundColor(ShiftKitColors.charcoalBrown)

                    HStack(spacing: 12) {
                        Button("Clean Temporary Files") {
                            let bytes = settings.cleanTemporaryFiles()
                            if bytes > 0 {
                                tempCleanedMessage = "Freed \(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)) of temporary files."
                            } else {
                                tempCleanedMessage = "No orphaned temporary files found."
                            }
                        }
                        .buttonStyle(ShiftKitSecondaryButtonStyle())

                        Button("Clear Operation History") {
                            JobHistoryStore.shared.clearHistory()
                            tempCleanedMessage = "Operation history cleared."
                        }
                        .buttonStyle(ShiftKitSecondaryButtonStyle())
                    }

                    if let tempCleanedMessage {
                        Text(tempCleanedMessage)
                            .font(ShiftKitTypography.caption)
                            .foregroundColor(ShiftKitColors.deepOlive)
                    }
                }
            }
        }
    }

    // MARK: - 6. About Section
    @ViewBuilder
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "About ShiftKit", subtitle: "Local-first circular action menu for macOS.")

            ShiftKitCard {
                VStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(ShiftKitColors.surface)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Circle().stroke(ShiftKitColors.border, lineWidth: 1)
                            )
                        Image(systemName: "arrow.triangle.swap")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(ShiftKitColors.deepOlive)
                    }

                    Text("ShiftKit")
                        .font(ShiftKitTypography.titleLarge)
                        .foregroundColor(ShiftKitColors.charcoalBrown)

                    Text("Hold Shift while dragging any file to convert, compress, crop, trim, merge, and edit locally.")
                        .font(ShiftKitTypography.body)
                        .foregroundColor(ShiftKitColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Divider().overlay(ShiftKitColors.borderSubtle)

                    VStack(spacing: 4) {
                        Text("Created for macOS with AppKit, SwiftUI, PDFKit, and FFmpeg.")
                            .font(ShiftKitTypography.caption)
                            .foregroundColor(ShiftKitColors.textMuted)
                        Text("Light-only warm aesthetic. Strictly zero tracking.")
                            .font(ShiftKitTypography.caption)
                            .foregroundColor(ShiftKitColors.textMuted)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(ShiftKitTypography.title)
                .foregroundColor(ShiftKitColors.charcoalBrown)
            Text(subtitle)
                .font(ShiftKitTypography.caption)
                .foregroundColor(ShiftKitColors.textMuted)
        }
        .padding(.bottom, 4)
    }

    private func selectOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"

        if panel.runModal() == .OK, let selectedURL = panel.url {
            settings.outputDirectoryPath = selectedURL.path
        }
    }
}
