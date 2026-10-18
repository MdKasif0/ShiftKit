import SwiftUI
import AppKit

public struct MainView: View {
    @Bindable var coordinator: AppCoordinator

    public init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        ZStack {
            // Background canvas
            ShiftKitColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack(alignment: .center) {
                    HStack(spacing: 10) {
                        // App Brand Icon
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 34, height: 34)

                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 6) {
                                Text("ShiftKit")
                                    .font(ShiftKitTypography.title)
                                    .foregroundColor(ShiftKitColors.charcoalBrown)

                                ShiftKitPill("v1.0", tint: ShiftKitColors.charcoalBrown.opacity(0.8), background: ShiftKitColors.softCream)
                            }
                            Text("Radial File Action Utility")
                                .font(ShiftKitTypography.caption)
                                .foregroundColor(ShiftKitColors.textMuted)
                        }
                    }

                    Spacer()

                    // Local Processing Status Indicator
                    LocalProcessingBadge()

                    // Settings Button
                    Button {
                        coordinator.isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ShiftKitColors.charcoalBrown)
                            .frame(width: 30, height: 30)
                            .background(ShiftKitColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(ShiftKitColors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("ShiftKit Preferences")
                    .accessibilityLabel("Settings")
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
                .background(ShiftKitColors.surfaceSecondary.opacity(0.8))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(ShiftKitColors.border),
                    alignment: .bottom
                )

                // Scrollable Content Area
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 18) {
                        // 1. Signature Interaction Explainer
                        ShiftInteractionExplainerView()

                        // 2. Central Drag-and-Drop Area (with alternative workflow)
                        DropZoneView(
                            inspectedFile: $coordinator.inspectedFile,
                            onFileDropped: { url in
                                coordinator.handleFileSelected(url: url)
                            },
                            onSelectAction: { action in
                                if let file = coordinator.inspectedFile {
                                    coordinator.executeAction(action, on: file)
                                }
                            },
                            onOpenRadialWindow: { file in
                                coordinator.radialMenuCoordinator.presentFloatingWindow(for: file) { action in
                                    coordinator.executeAction(action, on: file)
                                }
                            }
                        )

                        // 3. Interactive Radial Menu Preview / Simulator
                        RadialMenuPreviewCard { file, action in
                            coordinator.executeAction(action, on: file)
                        }

                        // 4. Recent Operations Section
                        RecentOperationsView(
                            activeJobs: coordinator.jobManager.activeJobs,
                            completedJobs: coordinator.jobManager.completedJobs,
                            onRevealInFinder: { url in
                                coordinator.revealInFinder(url: url)
                            },
                            onClearHistory: {
                                coordinator.clearCompleted()
                            },
                            onCancelJob: { id in
                                coordinator.jobManager.cancelJob(id: id)
                            }
                        )
                    }
                    .padding(22)
                }

                // Bottom Status Bar
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(ShiftKitColors.mutedSage)
                            .frame(width: 6, height: 6)
                        Text("Ready • All conversion engines sandboxed on this Mac")
                            .font(ShiftKitTypography.caption)
                            .foregroundColor(ShiftKitColors.textSecondary)
                    }

                    Spacer()

                    Text("Hold Shift while dragging to activate anywhere")
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.textMuted)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 8)
                .background(ShiftKitColors.surfaceSecondary.opacity(0.6))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(ShiftKitColors.borderSubtle),
                    alignment: .top
                )
            }
        }
        .frame(minWidth: 540, idealWidth: 620, maxWidth: 720, minHeight: 680, idealHeight: 740)
        .preferredColorScheme(.light)
        .sheet(isPresented: $coordinator.isSettingsPresented) {
            SettingsView(settings: coordinator.settingsStore)
        }
        .onAppear {
            coordinator.startMenuBar()
        }
        .onOpenURL { url in
            coordinator.handleFileSelected(url: url)
        }
    }
}
