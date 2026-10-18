import SwiftUI

public struct RecentOperationsView: View {
    public let activeJobs: [ConversionJob]
    public let completedJobs: [ConversionJob]
    public let onRevealInFinder: (URL) -> Void
    public let onClearHistory: () -> Void
    public let onCancelJob: ((UUID) -> Void)?

    public init(
        activeJobs: [ConversionJob],
        completedJobs: [ConversionJob],
        onRevealInFinder: @escaping (URL) -> Void,
        onClearHistory: @escaping () -> Void,
        onCancelJob: ((UUID) -> Void)? = nil
    ) {
        self.activeJobs = activeJobs
        self.completedJobs = completedJobs
        self.onRevealInFinder = onRevealInFinder
        self.onClearHistory = onClearHistory
        self.onCancelJob = onCancelJob
    }

    public var body: some View {
        ShiftKitCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text("Recent Operations")
                        .font(ShiftKitTypography.headline)
                        .foregroundColor(ShiftKitColors.charcoalBrown)

                    Spacer()

                    if !completedJobs.isEmpty {
                        Button("Clear") {
                            onClearHistory()
                        }
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.textMuted)
                        .buttonStyle(.plain)
                    }
                }

                if activeJobs.isEmpty && completedJobs.isEmpty {
                    // Empty state
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 20))
                                .foregroundColor(ShiftKitColors.sandBeige)
                            Text("No recent conversion operations")
                                .font(ShiftKitTypography.caption)
                                .foregroundColor(ShiftKitColors.textMuted)
                        }
                        .padding(.vertical, 14)
                        Spacer()
                    }
                } else {
                    VStack(spacing: 8) {
                        // Active jobs first
                        ForEach(activeJobs) { job in
                            ActiveJobRow(job: job, onCancel: onCancelJob)
                        }

                        // Completed jobs
                        ForEach(completedJobs.prefix(5)) { job in
                            CompletedJobRow(job: job, onReveal: onRevealInFinder)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Active Job Row
private struct ActiveJobRow: View {
    let job: ConversionJob
    let onCancel: ((UUID) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: job.request.fileType.systemIcon)
                    .foregroundColor(ShiftKitColors.deepOlive)
                    .font(.system(size: 13))

                VStack(alignment: .leading, spacing: 1) {
                    Text(job.sourceFileName)
                        .font(ShiftKitTypography.subheadline)
                        .foregroundColor(ShiftKitColors.charcoalBrown)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(job.actionTitle)
                            .font(ShiftKitTypography.captionBold)
                            .foregroundColor(ShiftKitColors.deepOlive)

                        if let started = job.startedAt {
                            Text("•")
                                .font(ShiftKitTypography.caption)
                                .foregroundColor(ShiftKitColors.textMuted)
                            TimelineView(.periodic(from: .now, by: 0.5)) { context in
                                let elapsed = context.date.timeIntervalSince(started)
                                Text(String(format: "%.1fs elapsed", max(0.0, elapsed)))
                                    .font(ShiftKitTypography.code)
                                    .foregroundColor(ShiftKitColors.textMuted)
                            }
                        }
                    }
                }

                Spacer()

                // Cancel Button
                if let onCancel {
                    Button {
                        onCancel(job.id)
                    } label: {
                        Text("Cancel")
                            .font(ShiftKitTypography.caption)
                            .foregroundColor(ShiftKitColors.softTerracotta)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(ShiftKitColors.warmPeach.opacity(0.5))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                ShiftKitPill(
                    job.status.displayText,
                    icon: "arrow.triangle.2.circlepath",
                    tint: ShiftKitColors.softTerracotta,
                    background: ShiftKitColors.warmPeach.opacity(0.4)
                )
            }

            // Honest Progress View
            switch job.status {
            case .running(let progress, let stage):
                VStack(alignment: .leading, spacing: 3) {
                    if progress > 0 {
                        ProgressView(value: progress)
                            .tint(ShiftKitColors.softTerracotta)
                    } else {
                        ProgressView()
                            .progressViewStyle(.linear)
                            .tint(ShiftKitColors.softTerracotta)
                    }
                    Text(stage)
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.textMuted)
                }
            case .inspecting:
                VStack(alignment: .leading, spacing: 3) {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .tint(ShiftKitColors.mutedSage)
                    Text("Inspecting files and validating pipeline...")
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.textMuted)
                }
            case .ready:
                Text("Queued and ready to process")
                    .font(ShiftKitTypography.caption)
                    .foregroundColor(ShiftKitColors.textMuted)
            default:
                EmptyView()
            }
        }
        .padding(10)
        .background(ShiftKitColors.softCream)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(ShiftKitColors.sandBeige, lineWidth: 1)
        )
    }
}

// MARK: - Completed / Failed Job Row
private struct CompletedJobRow: View {
    let job: ConversionJob
    let onReveal: (URL) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: job.request.fileType.systemIcon)
                .foregroundColor(iconColor)
                .font(.system(size: 13))
                .frame(width: 24, height: 24)
                .background(ShiftKitColors.softCream)
                .clipShape(RoundedRectangle(cornerRadius: 5))

            VStack(alignment: .leading, spacing: 2) {
                Text(job.sourceFileName)
                    .font(ShiftKitTypography.body)
                    .foregroundColor(ShiftKitColors.charcoalBrown)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(job.actionTitle)
                        .font(ShiftKitTypography.captionBold)
                        .foregroundColor(titleColor)

                    switch job.status {
                    case .completed(_, let duration, let size):
                        Text("•")
                            .font(ShiftKitTypography.caption)
                            .foregroundColor(ShiftKitColors.textMuted)
                        Text(String(format: "%.2fs", duration))
                            .font(ShiftKitTypography.code)
                            .foregroundColor(ShiftKitColors.textMuted)

                        if size > 0 {
                            Text("•")
                                .font(ShiftKitTypography.caption)
                                .foregroundColor(ShiftKitColors.textMuted)
                            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                                .font(ShiftKitTypography.code)
                                .foregroundColor(ShiftKitColors.deepOlive)
                        }

                    case .failed(let err):
                        Text("•")
                            .font(ShiftKitTypography.caption)
                            .foregroundColor(ShiftKitColors.textMuted)
                        Text(err.localizedDescription)
                            .font(ShiftKitTypography.caption)
                            .foregroundColor(ShiftKitColors.softTerracotta)
                            .lineLimit(1)

                    case .cancelled:
                        Text("• Cancelled")
                            .font(ShiftKitTypography.caption)
                            .foregroundColor(ShiftKitColors.textMuted)

                    default:
                        EmptyView()
                    }
                }
            }

            Spacer()

            if let outURL = job.outputURL {
                Button {
                    onReveal(outURL)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                        Text("Finder")
                    }
                }
                .buttonStyle(ShiftKitSecondaryButtonStyle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(ShiftKitColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(ShiftKitColors.borderSubtle, lineWidth: 1)
        )
    }

    private var iconColor: Color {
        switch job.status {
        case .completed: return ShiftKitColors.deepOlive
        case .failed: return ShiftKitColors.softTerracotta
        case .cancelled: return ShiftKitColors.textMuted
        default: return ShiftKitColors.deepOlive
        }
    }

    private var titleColor: Color {
        switch job.status {
        case .completed: return ShiftKitColors.deepOlive
        case .failed: return ShiftKitColors.softTerracotta
        case .cancelled: return ShiftKitColors.textMuted
        default: return ShiftKitColors.deepOlive
        }
    }
}
