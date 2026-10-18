import SwiftUI

public struct UpdateSettingsView: View {
    @Bindable var updateManager: UpdateManager

    public init(updateManager: UpdateManager) {
        self.updateManager = updateManager
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            VStack(alignment: .leading, spacing: 2) {
                Text("ShiftKit Updates")
                    .font(ShiftKitTypography.title)
                    .foregroundColor(ShiftKitColors.charcoalBrown)
                Text("Secure, on-device automatic application updates powered by Sparkle 2.")
                    .font(ShiftKitTypography.caption)
                    .foregroundColor(ShiftKitColors.textMuted)
            }
            .padding(.bottom, 4)

            // 1. Current Version & Manual Check Card
            ShiftKitCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Current Installation")
                                .font(ShiftKitTypography.caption)
                                .foregroundColor(ShiftKitColors.textMuted)

                            HStack(spacing: 8) {
                                Text("ShiftKit v\(updateManager.currentVersion)")
                                    .font(ShiftKitTypography.headline)
                                    .foregroundColor(ShiftKitColors.charcoalBrown)

                                ShiftKitPill(
                                    "Build \(updateManager.currentBuild)",
                                    tint: ShiftKitColors.charcoalBrown,
                                    background: ShiftKitColors.softCream
                                )
                            }
                        }

                        Spacer()

                        Button {
                            updateManager.checkForUpdates()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Check for Updates")
                                    .font(ShiftKitTypography.body)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(ShiftKitColors.softTerracotta)
                            .foregroundColor(ShiftKitColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(updateManager.state == .checking)
                    }

                    Divider().overlay(ShiftKitColors.borderSubtle)

                    // Dynamic Status Card
                    UpdateStatusView(
                        state: updateManager.state,
                        lastCheckDate: updateManager.lastCheckDate,
                        onRetry: {
                            updateManager.checkForUpdates()
                        }
                    )
                }
            }

            // 2. Automated Preferences Card
            ShiftKitCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Update Preferences")
                        .font(ShiftKitTypography.headline)
                        .foregroundColor(ShiftKitColors.charcoalBrown)

                    Toggle(
                        "Automatically check for updates",
                        isOn: Binding(
                            get: { updateManager.automaticallyChecksForUpdates },
                            set: { updateManager.automaticallyChecksForUpdates = $0 }
                        )
                    )
                    .font(ShiftKitTypography.body)
                    .foregroundColor(ShiftKitColors.charcoalBrown)
                    .toggleStyle(CheckboxToggleStyle())

                    Toggle(
                        "Automatically download updates in background",
                        isOn: Binding(
                            get: { updateManager.automaticallyDownloadsUpdates },
                            set: { updateManager.automaticallyDownloadsUpdates = $0 }
                        )
                    )
                    .font(ShiftKitTypography.body)
                    .foregroundColor(ShiftKitColors.charcoalBrown)
                    .toggleStyle(CheckboxToggleStyle())

                    Text("ShiftKit will alert you when an update is verified and ready for installation. Your open documents and tasks are never interrupted.")
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.textSecondary)
                }
            }

            // 3. Security & Release Notes Card
            ShiftKitCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 14))
                            .foregroundColor(ShiftKitColors.deepOlive)
                        Text("Cryptographic Verification")
                            .font(ShiftKitTypography.headline)
                            .foregroundColor(ShiftKitColors.charcoalBrown)
                    }

                    Text("All update packages are cryptographically signed with 256-bit EdDSA signatures and verified on your Mac prior to extraction. Unsigned or corrupted archives are automatically rejected.")
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.textSecondary)

                    Divider().overlay(ShiftKitColors.borderSubtle)

                    HStack {
                        if let urlString = updateManager.feedURLString, let url = URL(string: urlString) {
                            Link(destination: url) {
                                HStack(spacing: 5) {
                                    Text("View Appcast Feed")
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 10))
                                }
                                .font(ShiftKitTypography.caption)
                                .foregroundColor(ShiftKitColors.deepOlive)
                            }
                        }

                        Spacer()

                        Link(destination: URL(string: "https://github.com/MdKasif0/ShiftKit/releases")!) {
                            HStack(spacing: 5) {
                                Text("Release Notes & Changelog")
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10))
                            }
                            .font(ShiftKitTypography.caption)
                            .foregroundColor(ShiftKitColors.softTerracotta)
                        }
                    }
                }
            }
        }
    }
}
