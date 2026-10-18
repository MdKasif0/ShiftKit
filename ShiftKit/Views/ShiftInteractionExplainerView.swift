import SwiftUI

public struct ShiftInteractionExplainerView: View {
    public init() {}

    public var body: some View {
        ShiftKitCard(padding: 14, backgroundColor: ShiftKitColors.softCream.opacity(0.65)) {
            HStack(spacing: 16) {
                // Key badge
                VStack(spacing: 4) {
                    HStack(spacing: 3) {
                        Image(systemName: "shift")
                            .font(.system(size: 13, weight: .bold))
                        Text("Shift")
                            .font(ShiftKitTypography.captionBold)
                    }
                    .foregroundColor(ShiftKitColors.charcoalBrown)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ShiftKitColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ShiftKitColors.sandBeige, lineWidth: 1)
                    )
                    .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.06), radius: 2, x: 0, y: 1)

                    Text("Hold Key")
                        .font(ShiftKitTypography.caption)
                        .foregroundColor(ShiftKitColors.textMuted)
                }

                // Step sequence
                HStack(spacing: 12) {
                    StepItem(number: "1", title: "Hold Shift", description: "While dragging any file from Finder")
                    Divider().frame(height: 28).overlay(ShiftKitColors.border)
                    StepItem(number: "2", title: "Radial Ring", description: "Action menu appears at your cursor")
                    Divider().frame(height: 28).overlay(ShiftKitColors.border)
                    StepItem(number: "3", title: "Instant Process", description: "File converts locally on your Mac")
                }

                Spacer()
            }
        }
    }
}

private struct StepItem: View {
    let number: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(ShiftKitTypography.captionBold)
                .foregroundColor(ShiftKitColors.softTerracotta)
                .frame(width: 18, height: 18)
                .background(ShiftKitColors.warmPeach.opacity(0.5))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ShiftKitTypography.subheadline)
                    .foregroundColor(ShiftKitColors.charcoalBrown)
                Text(description)
                    .font(ShiftKitTypography.caption)
                    .foregroundColor(ShiftKitColors.textMuted)
            }
        }
    }
}
