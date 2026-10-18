import SwiftUI

// MARK: - Radial Menu Segment Component
public struct RadialMenuSegment: View {
    public let item: RadialSegmentItem
    public let index: Int
    public let geometry: MenuGeometry
    public let isHovered: Bool
    public let isFocused: Bool
    public let isSelected: Bool
    public let onSelect: () -> Void

    public init(
        item: RadialSegmentItem,
        index: Int,
        geometry: MenuGeometry = MenuGeometry(),
        isHovered: Bool = false,
        isFocused: Bool = false,
        isSelected: Bool = false,
        onSelect: @escaping () -> Void
    ) {
        self.item = item
        self.index = index
        self.geometry = geometry
        self.isHovered = isHovered
        self.isFocused = isFocused
        self.isSelected = isSelected
        self.onSelect = onSelect
    }

    private var isActiveHighlight: Bool {
        isHovered || isFocused
    }

    public var body: some View {
        let angles = MenuLayoutEngine.shared.angleRange(for: index, geometry: geometry)
        let outerR = isActiveHighlight ? (geometry.outerRadius + 7) : geometry.outerRadius
        let innerR = geometry.innerRadius

        ZStack {
            // Sector Shape
            RadialSectorShape(
                startAngle: angles.start,
                endAngle: angles.end,
                innerRadius: innerR,
                outerRadius: outerR
            )
            .fill(segmentBackgroundColor)
            .overlay(
                RadialSectorShape(
                    startAngle: angles.start,
                    endAngle: angles.end,
                    innerRadius: innerR,
                    outerRadius: outerR
                )
                .stroke(segmentBorderColor, lineWidth: segmentBorderWidth)
            )
            .shadow(
                color: ShiftKitColors.charcoalBrown.opacity(isActiveHighlight ? 0.12 : 0.0),
                radius: 5,
                x: 0,
                y: 2
            )

            // Content Placement (Icon, Title, Shortcut badge)
            let midDistance = (innerR + geometry.outerRadius) / 2.0 + (isActiveHighlight ? 2 : 0)
            let centerPoint = CGPoint(
                x: geometry.totalDiameter / 2.0,
                y: geometry.totalDiameter / 2.0
            )
            let contentPos = MenuLayoutEngine.shared.pointOnCircle(
                radius: midDistance,
                angle: angles.mid,
                center: centerPoint
            )

            VStack(spacing: 2) {
                // Number shortcut badge
                Text(item.shortcutKey)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(shortcutTextColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(shortcutBackgroundColor)
                    .clipShape(Capsule())

                // Action Icon
                Image(systemName: item.systemIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(contentForegroundColor)

                // Action Title
                Text(item.title)
                    .font(ShiftKitTypography.radialLabel)
                    .foregroundColor(contentForegroundColor)
                    .lineLimit(1)
            }
            .position(contentPos)
        }
        .animation(.easeInOut(duration: 0.14), value: isHovered)
        .animation(.easeInOut(duration: 0.14), value: isFocused)
        .animation(.easeInOut(duration: 0.14), value: isSelected)
        .contentShape(
            RadialSectorShape(
                startAngle: angles.start,
                endAngle: angles.end,
                innerRadius: innerR,
                outerRadius: geometry.outerRadius + 8
            )
        )
        .onTapGesture {
            guard item.isEnabled else { return }
            onSelect()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title) (Key: \(item.shortcutKey)): \(item.subtitle)")
        .accessibilityAddTraits(item.isEnabled ? .isButton : .isStaticText)
    }

    // MARK: - Color States
    private var segmentBackgroundColor: Color {
        guard item.isEnabled else {
            return ShiftKitColors.softCream.opacity(0.4)
        }
        if isSelected {
            return ShiftKitColors.softTerracotta
        } else if isHovered {
            return ShiftKitColors.warmPeach
        } else if isFocused {
            return ShiftKitColors.softCream
        } else {
            return ShiftKitColors.surface
        }
    }

    private var segmentBorderColor: Color {
        guard item.isEnabled else {
            return ShiftKitColors.sandBeige.opacity(0.3)
        }
        if isSelected {
            return ShiftKitColors.deepOlive
        } else if isHovered || isFocused {
            return ShiftKitColors.softTerracotta
        } else {
            return ShiftKitColors.sandBeige
        }
    }

    private var segmentBorderWidth: CGFloat {
        if isSelected || isFocused {
            return 2.0
        } else if isHovered {
            return 1.5
        } else {
            return 1.0
        }
    }

    private var contentForegroundColor: Color {
        guard item.isEnabled else {
            return ShiftKitColors.charcoalBrown.opacity(0.28)
        }
        if isSelected {
            return ShiftKitColors.pureWhite
        } else if isHovered || isFocused {
            return ShiftKitColors.charcoalBrown
        } else {
            return ShiftKitColors.deepOlive
        }
    }

    private var shortcutTextColor: Color {
        if isSelected {
            return ShiftKitColors.softTerracotta
        } else {
            return ShiftKitColors.charcoalBrown.opacity(0.7)
        }
    }

    private var shortcutBackgroundColor: Color {
        if isSelected {
            return ShiftKitColors.pureWhite
        } else {
            return ShiftKitColors.softCream.opacity(0.85)
        }
    }
}
