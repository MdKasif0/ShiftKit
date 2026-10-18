import SwiftUI
import AppKit

public struct JobQueueStudioView: View {
    @Bindable var jobManager: JobManager
    @Bindable var historyStore: JobHistoryStore

    @State private var selectedSegment: StudioSegment = .queue
    @State private var historyFilter: HistoryFilter = .all
    @State private var searchText: String = ""

    public enum StudioSegment: String, CaseIterable, Identifiable {
        case queue = "Active Queue"
        case history = "Recent History"
        public var id: String { rawValue }
    }

    public enum HistoryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case completed = "Completed"
        case failed = "Failed"
        public var id: String { rawValue }
    }

    public init(jobManager: JobManager = .shared, historyStore: JobHistoryStore = .shared) {
        self.jobManager = jobManager
        self.historyStore = historyStore
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ShiftKitColors.deepOlive)
                    Text("Job Queue & History")
                        .font(ShiftKitTypography.headline)
                        .foregroundColor(ShiftKitColors.charcoalBrown)
                }

                Spacer()

                Picker("", selection: $selectedSegment) {
                    Text("Queue (\(jobManager.activeJobs.count))").tag(StudioSegment.queue)
                    Text("History (\(historyStore.items.count))").tag(StudioSegment.history)
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(ShiftKitColors.surfaceSecondary)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(ShiftKitColors.border),
                alignment: .bottom
            )

            // Body Content
            if selectedSegment == .queue {
                queueView
            } else {
                historyView
            }
        }
        .frame(minWidth: 580, idealWidth: 640, maxWidth: 780, minHeight: 460, idealHeight: 520)
        .background(ShiftKitColors.background)
        .preferredColorScheme(.light)
    }

    // MARK: - Queue View
    @ViewBuilder
    private var queueView: some View {
        VStack(spacing: 0) {
            // Queue Action Header
            HStack {
                let summary = jobManager.batchSummary
                HStack(spacing: 8) {
                    ShiftKitPill("Total: \(summary.total)", tint: ShiftKitColors.charcoalBrown, background: ShiftKitColors.softCream)
                    if summary.running > 0 {
                        ShiftKitPill("Running: \(summary.running)", tint: ShiftKitColors.deepOlive, background: ShiftKitColors.mutedSage.opacity(0.3))
                    }
                    if summary.queued > 0 {
                        ShiftKitPill("Queued: \(summary.queued)", tint: ShiftKitColors.textSecondary, background: ShiftKitColors.surfaceSecondary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    if !jobManager.activeJobs.isEmpty {
                        Button(jobManager.isPaused ? "Resume Queue" : "Pause Queue") {
                            if jobManager.isPaused {
                                jobManager.resumeQueue()
                            } else {
                                jobManager.pauseQueue()
                            }
                        }
                        .buttonStyle(ShiftKitSecondaryButtonStyle())
                        .accessibilityLabel(jobManager.isPaused ? "Resume Queue" : "Pause Queue")

                        Button("Cancel All") {
                            jobManager.cancelAllActiveJobs()
                        }
                        .buttonStyle(ShiftKitSecondaryButtonStyle())
                        .accessibilityLabel("Cancel all active and queued jobs")
                    }

                    if !jobManager.failedJobs.isEmpty {
                        Button("Retry Failed (\(jobManager.failedJobs.count))") {
                            jobManager.retryAllFailedJobs()
                        }
                        .buttonStyle(ShiftKitSecondaryButtonStyle())
                        .accessibilityLabel("Retry all failed conversions")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(ShiftKitColors.surfaceSecondary.opacity(0.5))

            if jobManager.activeJobs.isEmpty {
                emptyQueueView
            } else {
                List {
                    ForEach(jobManager.activeJobs) { job in
                        ActiveJobCard(job: job) {
                            jobManager.cancelJob(id: job.id)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var emptyQueueView: some View {
        VStack(spacing: 12) {
            Spacer()
            Circle()
                .fill(ShiftKitColors.softCream)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "tray")
                        .font(.system(size: 24))
                        .foregroundColor(ShiftKitColors.mutedSage)
                )

            Text("No Active Jobs")
                .font(ShiftKitTypography.headline)
                .foregroundColor(ShiftKitColors.charcoalBrown)

            Text("Hold Shift while dragging files from Finder to queue conversions.")
                .font(ShiftKitTypography.caption)
                .foregroundColor(ShiftKitColors.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - History View
    @ViewBuilder
    private var historyView: some View {
        VStack(spacing: 0) {
            // Filter Bar
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ShiftKitColors.textMuted)
                        .font(.system(size: 12))
                    TextField("Filter history by filename...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(ShiftKitTypography.body)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ShiftKitColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6).stroke(ShiftKitColors.border, lineWidth: 1)
                )

                Picker("", selection: $historyFilter) {
                    ForEach(HistoryFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                if !historyStore.items.isEmpty {
                    Button("Clear History") {
                        historyStore.clearHistory()
                    }
                    .buttonStyle(ShiftKitSecondaryButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(ShiftKitColors.surfaceSecondary.opacity(0.5))

            let filtered = filteredHistoryItems

            if filtered.isEmpty {
                emptyHistoryView
            } else {
                List {
                    ForEach(filtered) { item in
                        HistoryItemRow(item: item) { url in
                            historyStore.revealInFinder(url: url)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var filteredHistoryItems: [HistoryItem] {
        historyStore.items.filter { item in
            let matchesSearch = searchText.isEmpty || item.filename.localizedCaseInsensitiveContains(searchText) || item.operationTitle.localizedCaseInsensitiveContains(searchText)
            switch historyFilter {
            case .all:
                return matchesSearch
            case .completed:
                return matchesSearch && item.isSuccess
            case .failed:
                return matchesSearch && (item.isFailed || item.isCancelled)
            }
        }
    }

    @ViewBuilder
    private var emptyHistoryView: some View {
        VStack(spacing: 12) {
            Spacer()
            Circle()
                .fill(ShiftKitColors.softCream)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "clock")
                        .font(.system(size: 24))
                        .foregroundColor(ShiftKitColors.mutedSage)
                )

            Text("No Operation History")
                .font(ShiftKitTypography.headline)
                .foregroundColor(ShiftKitColors.charcoalBrown)

            Text("Completed file transformations and utilities are listed here locally.")
                .font(ShiftKitTypography.caption)
                .foregroundColor(ShiftKitColors.textMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Active Job Card
private struct ActiveJobCard: View {
    let job: ConversionJob
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: job.operation.systemIcon)
                    .foregroundColor(ShiftKitColors.deepOlive)
                    .font(.system(size: 14))

                VStack(alignment: .leading, spacing: 1) {
                    Text(job.sourceFileName)
                        .font(ShiftKitTypography.headline)
                        .foregroundColor(ShiftKitColors.charcoalBrown)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(job.actionTitle)
                            .font(ShiftKitTypography.captionBold)
                            .foregroundColor(ShiftKitColors.deepOlive)

                        if let format = job.outputFormat {
                            Text("→ \(format.displayName)")
                                .font(ShiftKitTypography.caption)
                                .foregroundColor(ShiftKitColors.textMuted)
                        }

                        if let started = job.startedAt {
                            TimelineView(.periodic(from: .now, by: 0.5)) { context in
                                let elapsed = context.date.timeIntervalSince(started)
                                Text(String(format: "• %.1fs", max(0.0, elapsed)))
                                    .font(ShiftKitTypography.code)
                                    .foregroundColor(ShiftKitColors.textMuted)
                            }
                        }
                    }
                }

                Spacer()

                Button("Cancel", action: onCancel)
                    .buttonStyle(ShiftKitSecondaryButtonStyle())

                ShiftKitPill(
                    job.status.displayText,
                    tint: statusColor,
                    background: statusBackground
                )
            }

            // Progress Bar
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
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(ShiftKitColors.mutedSage)
            default:
                EmptyView()
            }
        }
        .padding(12)
        .background(ShiftKitColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(ShiftKitColors.border, lineWidth: 1)
        )
    }

    private var statusColor: Color {
        switch job.status {
        case .running: return ShiftKitColors.softTerracotta
        case .inspecting, .ready: return ShiftKitColors.deepOlive
        default: return ShiftKitColors.textSecondary
        }
    }

    private var statusBackground: Color {
        switch job.status {
        case .running: return ShiftKitColors.warmPeach.opacity(0.4)
        case .inspecting, .ready: return ShiftKitColors.mutedSage.opacity(0.3)
        default: return ShiftKitColors.softCream
        }
    }
}

// MARK: - History Item Row
private struct HistoryItemRow: View {
    let item: HistoryItem
    let onReveal: (URL) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.operationIcon)
                .foregroundColor(iconColor)
                .font(.system(size: 14))
                .frame(width: 28, height: 28)
                .background(ShiftKitColors.softCream)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.filename)
                        .font(ShiftKitTypography.body)
                        .foregroundColor(ShiftKitColors.charcoalBrown)
                        .lineLimit(1)

                    if item.fileCount > 1 {
                        ShiftKitPill("+\(item.fileCount - 1) files", tint: ShiftKitColors.charcoalBrown, background: ShiftKitColors.softCream)
                    }
                }

                HStack(spacing: 6) {
                    Text(item.operationTitle)
                        .font(ShiftKitTypography.captionBold)
                        .foregroundColor(iconColor)

                    Text("•")
                        .foregroundColor(ShiftKitColors.border)

                    Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.textMuted)

                    if let duration = item.duration {
                        Text("• \(String(format: "%.2fs", duration))")
                            .font(ShiftKitTypography.code)
                            .foregroundColor(ShiftKitColors.textMuted)
                    }

                    if let size = item.outputSize, size > 0 {
                        Text("• \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
                            .font(ShiftKitTypography.code)
                            .foregroundColor(ShiftKitColors.deepOlive)
                    }
                }

                if let err = item.errorMessage {
                    Text(err)
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.softTerracotta)
                        .lineLimit(2)
                }
            }

            Spacer()

            if let outURL = item.outputURL {
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

            ShiftKitPill(
                item.status.capitalized,
                tint: iconColor,
                background: badgeBackground
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ShiftKitColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(ShiftKitColors.borderSubtle, lineWidth: 1)
        )
    }

    private var iconColor: Color {
        if item.isSuccess { return ShiftKitColors.deepOlive }
        if item.isFailed { return ShiftKitColors.softTerracotta }
        return ShiftKitColors.textMuted
    }

    private var badgeBackground: Color {
        if item.isSuccess { return ShiftKitColors.mutedSage.opacity(0.3) }
        if item.isFailed { return ShiftKitColors.warmPeach.opacity(0.4) }
        return ShiftKitColors.softCream
    }
}
