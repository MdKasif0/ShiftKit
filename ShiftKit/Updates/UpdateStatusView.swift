import SwiftUI

public struct UpdateStatusView: View {
    let state: UpdateState
    let lastCheckDate: Date?
    let onRetry: (() -> Void)?

    public init(state: UpdateState, lastCheckDate: Date?, onRetry: (() -> Void)? = nil) {
        self.state = state
        self.lastCheckDate = lastCheckDate
        self.onRetry = onRetry
    }

    public var body: some View {
        HStack(spacing: 12) {
            statusIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(ShiftKitTypography.headline)
                    .foregroundColor(ShiftKitColors.charcoalBrown)

                Text(statusSubtitle)
                    .font(ShiftKitTypography.caption)
                    .foregroundColor(ShiftKitColors.textSecondary)
            }

            Spacer()

            if case .error = state, let onRetry {
                Button("Retry") {
                    onRetry()
                }
                .buttonStyle(ShiftKitSecondaryButtonStyle())
            }
        }
        .padding(14)
        .background(ShiftKitColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ShiftKitColors.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch state {
        case .idle:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(ShiftKitColors.mutedSage)
                .font(.system(size: 20))
        case .checking:
            ProgressView()
                .scaleEffect(0.8)
                .frame(width: 20, height: 20)
        case .upToDate:
            Image(systemName: "checkmark.shield.fill")
                .foregroundColor(ShiftKitColors.mutedSage)
                .font(.system(size: 20))
        case .updateAvailable:
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(ShiftKitColors.softTerracotta)
                .font(.system(size: 20))
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(ShiftKitColors.softTerracotta)
                .font(.system(size: 20))
        }
    }

    private var statusTitle: String {
        switch state {
        case .idle:
            return "ShiftKit is up to date"
        case .checking:
            return "Checking for Updates..."
        case .upToDate:
            return "ShiftKit is Up to Date"
        case .updateAvailable(let version):
            return "New Version Available: v\(version)"
        case .error:
            return "Update Check Failed"
        }
    }

    private var statusSubtitle: String {
        switch state {
        case .idle, .upToDate:
            if let date = lastCheckDate {
                return "Last checked: \(formattedDate(date))"
            } else {
                return "Automatic daily checks active"
            }
        case .checking:
            return "Connecting to secure update server..."
        case .updateAvailable:
            return "Sparkle installer will guide your update"
        case .error(let msg):
            return msg
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
