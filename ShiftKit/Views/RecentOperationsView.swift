import SwiftUI

public struct RecentOperationsView: View {
    public let activeJobs: [ConversionJob]
    public let completedJobs: [ConversionJob]
    public let onRevealInFinder: (URL) -> Void
    public let onClearHistory: () -> Void

    public init(
        activeJobs: [ConversionJob],
        completedJobs: [ConversionJob],
        onRevealInFinder: @escaping (URL) -> Void,
        onClearHistory: @escaping () -> Void
    ) {
        self.activeJobs = activeJobs
        self.completedJobs = completedJobs
        self.onRevealInFinder = onRevealInFinder
        self.onClearHistory = onClearHistory
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
                            ActiveJobRow(job: job)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: job.request.fileType.systemIcon)
                    .foregroundColor(ShiftKitColors.deepOlive)
                    .font(.system(size: 13))

                Text(job.sourceFileName)
                    .font(ShiftKitTypography.subheadline)
                    .foregroundColor(ShiftKitColors.charcoalBrown)
                    .lineLimit(1)

                Spacer()

                ShiftKitPill(job.status.displayText, icon: "arrow.triangle.2.circlepath", tint: ShiftKitColors.softTerracotta, background: ShiftKitColors.warmPeach.opacity(0.4))
            }

            if case .processing(let progress, _) = job.status {
                ProgressView(value: progress)
                    .tint(ShiftKitColors.softTerracotta)
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

// MARK: - Completed Job Row
private struct CompletedJobRow: View {
    let job: ConversionJob
    let onReveal: (URL) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: job.request.fileType.systemIcon)
                .foregroundColor(ShiftKitColors.deepOlive)
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
                        .foregroundColor(ShiftKitColors.deepOlive)

                    if case .completed(_, let duration) = job.status {
                        Text("•")
                            .font(ShiftKitTypography.caption)
                            .foregroundColor(ShiftKitColors.textMuted)
                        Text(String(format: "%.2fs", duration))
                            .font(ShiftKitTypography.code)
                            .foregroundColor(ShiftKitColors.textMuted)
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
}
