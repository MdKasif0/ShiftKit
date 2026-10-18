import SwiftUI

// MARK: - ShiftKit Card Container
public struct ShiftKitCard<Content: View>: View {
    private let content: Content
    private let padding: CGFloat
    private let backgroundColor: Color

    public init(
        padding: CGFloat = 16,
        backgroundColor: Color = ShiftKitColors.surface,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(ShiftKitColors.border, lineWidth: 1)
            )
            .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - ShiftKit Pill Tag
public struct ShiftKitPill: View {
    public let text: String
    public let icon: String?
    public let tint: Color
    public let background: Color

    public init(
        _ text: String,
        icon: String? = nil,
        tint: Color = ShiftKitColors.deepOlive,
        background: Color = ShiftKitColors.softCream
    ) {
        self.text = text
        self.icon = icon
        self.tint = tint
        self.background = background
    }

    public var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(ShiftKitTypography.captionBold)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(background)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(tint.opacity(0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - ShiftKit Button Styles
public struct ShiftKitPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ShiftKitTypography.headline)
            .foregroundColor(ShiftKitColors.pureWhite)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                configuration.isPressed
                    ? ShiftKitColors.softTerracotta.opacity(0.85)
                    : (isEnabled ? ShiftKitColors.softTerracotta : ShiftKitColors.sandBeige)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: ShiftKitColors.charcoalBrown.opacity(isEnabled ? 0.08 : 0.0), radius: 3, x: 0, y: 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

public struct ShiftKitSecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ShiftKitTypography.subheadline)
            .foregroundColor(ShiftKitColors.charcoalBrown)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                configuration.isPressed
                    ? ShiftKitColors.sandBeige
                    : ShiftKitColors.softCream
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(ShiftKitColors.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Local Processing Status Indicator
public struct LocalProcessingBadge: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(ShiftKitColors.mutedSage)
                .frame(width: 7, height: 7)
                .overlay(
                    Circle()
                        .stroke(ShiftKitColors.deepOlive.opacity(0.4), lineWidth: 1)
                )

            Text("100% Local • Zero Cloud Uploads")
                .font(ShiftKitTypography.captionBold)
                .foregroundColor(ShiftKitColors.deepOlive)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(ShiftKitColors.softCream)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(ShiftKitColors.sandBeige, lineWidth: 1)
        )
        .help("All conversions, compression, and analysis run purely offline on this Mac.")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Local processing status: All operations run offline on your Mac.")
    }
}
