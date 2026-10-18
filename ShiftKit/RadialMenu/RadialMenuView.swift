import SwiftUI

public struct RadialMenuView: View {
    public let file: InspectedFile
    public let actions: [ConversionAction]
    public let onSelectAction: (ConversionAction) -> Void
    public let onDismiss: () -> Void

    @State private var hoveredActionID: String?
    @State private var appearAnimation: Bool = false

    private let innerRadius: CGFloat = 46
    private let outerRadius: CGFloat = 118
    private let centerSize: CGFloat = 86

    public init(
        file: InspectedFile,
        actions: [ConversionAction],
        onSelectAction: @escaping (ConversionAction) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.file = file
        self.actions = actions
        self.onSelectAction = onSelectAction
        self.onDismiss = onDismiss
    }

    public var body: some View {
        let count = max(actions.count, 1)
        let sliceAngle = 360.0 / Double(count)

        ZStack {
            // Background blur/scrim for contrast
            Circle()
                .fill(ShiftKitColors.warmIvory.opacity(0.85))
                .frame(width: outerRadius * 2 + 30, height: outerRadius * 2 + 30)
                .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.12), radius: 24, x: 0, y: 8)

            // Outer guideline ring
            Circle()
                .stroke(ShiftKitColors.sandBeige, lineWidth: 1.5)
                .frame(width: outerRadius * 2, height: outerRadius * 2)

            // Radial Slices
            ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                let startAngle = Angle(degrees: Double(index) * sliceAngle - 90.0)
                let endAngle = Angle(degrees: Double(index + 1) * sliceAngle - 90.0)
                let midAngle = Angle(degrees: (Double(index) + 0.5) * sliceAngle - 90.0)
                let isHovered = hoveredActionID == action.id

                ZStack {
                    // Sector background
                    RadialSectorShape(
                        startAngle: startAngle,
                        endAngle: endAngle,
                        innerRadius: innerRadius,
                        outerRadius: isHovered ? (outerRadius + 8) : outerRadius
                    )
                    .fill(isHovered ? ShiftKitColors.warmPeach : ShiftKitColors.surface)
                    .overlay(
                        RadialSectorShape(
                            startAngle: startAngle,
                            endAngle: endAngle,
                            innerRadius: innerRadius,
                            outerRadius: isHovered ? (outerRadius + 8) : outerRadius
                        )
                        .stroke(isHovered ? ShiftKitColors.softTerracotta : ShiftKitColors.sandBeige, lineWidth: isHovered ? 2 : 1)
                    )
                    .shadow(color: ShiftKitColors.charcoalBrown.opacity(isHovered ? 0.12 : 0.0), radius: 6, x: 0, y: 2)

                    // Sector Content (Icon + Title)
                    let iconDistance = (innerRadius + outerRadius) / 2.0
                    let x = iconDistance * CGFloat(cos(midAngle.radians))
                    let y = iconDistance * CGFloat(sin(midAngle.radians))

                    VStack(spacing: 3) {
                        Image(systemName: action.systemIcon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isHovered ? ShiftKitColors.charcoalBrown : ShiftKitColors.deepOlive)

                        Text(action.title)
                            .font(ShiftKitTypography.radialLabel)
                            .foregroundColor(isHovered ? ShiftKitColors.charcoalBrown : ShiftKitColors.charcoalBrown.opacity(0.9))
                            .lineLimit(1)
                    }
                    .position(x: outerRadius + x + 15, y: outerRadius + y + 15)
                }
                .contentShape(
                    RadialSectorShape(
                        startAngle: startAngle,
                        endAngle: endAngle,
                        innerRadius: innerRadius,
                        outerRadius: outerRadius + 8
                    )
                )
                .onHover { hovering in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        hoveredActionID = hovering ? action.id : nil
                    }
                }
                .onTapGesture {
                    onSelectAction(action)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(action.title): \(action.subtitle)")
                .accessibilityAddTraits(.isButton)
            }

            // Central Hub with Source File Preview
            Circle()
                .fill(ShiftKitColors.softCream)
                .frame(width: centerSize, height: centerSize)
                .overlay(
                    Circle().stroke(ShiftKitColors.sandBeige, lineWidth: 2)
                )
                .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.08), radius: 4, x: 0, y: 2)

            VStack(spacing: 3) {
                Image(systemName: file.fileType.systemIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ShiftKitColors.deepOlive)

                Text(file.fileName)
                    .font(ShiftKitTypography.captionBold)
                    .foregroundColor(ShiftKitColors.charcoalBrown)
                    .lineLimit(1)
                    .frame(maxWidth: centerSize - 16)

                Text(file.metadata.formattedSize)
                    .font(ShiftKitTypography.code)
                    .foregroundColor(ShiftKitColors.textMuted)
            }
        }
        .frame(width: (outerRadius + 15) * 2, height: (outerRadius + 15) * 2)
        .scaleEffect(appearAnimation ? 1.0 : 0.85)
        .opacity(appearAnimation ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                appearAnimation = true
            }
            if hoveredActionID == nil {
                hoveredActionID = actions.first?.id
            }
        }
    }
}
