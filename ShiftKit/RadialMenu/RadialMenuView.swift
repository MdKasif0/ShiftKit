import SwiftUI

// MARK: - Production Radial Action Menu View
public struct RadialMenuView: View {
    public let file: InspectedFile
    public let segments: [RadialSegmentItem]
    public let onSelectAction: (ConversionAction) -> Void
    public let onDismiss: () -> Void

    @State private var hoveredIndex: Int?
    @State private var focusedIndex: Int = 0
    @State private var activeSubmenuSegment: RadialSegmentItem?
    @State private var appearAnimation: Bool = false

    private let layoutEngine = MenuLayoutEngine.shared
    private let geometry = MenuGeometry(
        innerRadius: 58,
        outerRadius: 156,
        centerHubRadius: 52,
        segmentCount: 8,
        startAngleOffset: -90.0
    )

    public init(
        file: InspectedFile,
        segments: [RadialSegmentItem]? = nil,
        registry: ConversionRegistering = ConversionRegistry.shared,
        onSelectAction: @escaping (ConversionAction) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.file = file
        self.segments = segments ?? registry.segments(for: file)
        self.onSelectAction = onSelectAction
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            if let activeSubmenu = activeSubmenuSegment {
                // Secondary Action Submenu View with Back Navigation
                ActionSubmenuView(
                    segment: activeSubmenu,
                    file: file,
                    onSelectAction: { action in
                        onSelectAction(action)
                    },
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeSubmenuSegment = nil
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.92).combined(with: .opacity),
                    removal: .scale(scale: 0.92).combined(with: .opacity)
                ))

            } else {
                // Primary 8-Segment Radial Wheel
                radialWheelContent
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
            }
        }
        .frame(width: geometry.totalDiameter, height: geometry.totalDiameter)
        .scaleEffect(appearAnimation ? 1.0 : 0.88)
        .opacity(appearAnimation ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                appearAnimation = true
            }
        }
        // Keyboard event handlers for circular navigation
        .focusable()
        .onKeyPress(.leftArrow) { moveFocus(step: -1); return .handled }
        .onKeyPress(.upArrow) { moveFocus(step: -1); return .handled }
        .onKeyPress(.rightArrow) { moveFocus(step: 1); return .handled }
        .onKeyPress(.downArrow) { moveFocus(step: 1); return .handled }
        .onKeyPress(.return) { activateFocused(); return .handled }
        .onKeyPress(.space) { activateFocused(); return .handled }
        .onKeyPress(.escape) { handleEscape(); return .handled }
        .onKeyPress(characters: CharacterSet(charactersIn: "12345678")) { press in
            if let num = Int(press.characters), num >= 1 && num <= segments.count {
                focusedIndex = num - 1
                activateFocused()
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - Radial Wheel Content
    private var radialWheelContent: some View {
        ZStack {
            // Ambient soft shadow backdrop
            Circle()
                .fill(ShiftKitColors.warmIvory.opacity(0.85))
                .frame(width: geometry.outerRadius * 2 + 20, height: geometry.outerRadius * 2 + 20)
                .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.12), radius: 20, x: 0, y: 6)

            // Outer guideline ring
            Circle()
                .stroke(ShiftKitColors.sandBeige, lineWidth: 1.5)
                .frame(width: geometry.outerRadius * 2, height: geometry.outerRadius * 2)

            // 8 Radial Segments
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                RadialMenuSegment(
                    item: segment,
                    index: index,
                    geometry: geometry,
                    isHovered: hoveredIndex == index,
                    isFocused: focusedIndex == index && hoveredIndex == nil,
                    isSelected: activeSubmenuSegment?.id == segment.id,
                    onSelect: {
                        focusedIndex = index
                        handleSegmentSelected(segment)
                    }
                )
                .onHover { isHovering in
                    withAnimation(.easeInOut(duration: 0.14)) {
                        if isHovering {
                            hoveredIndex = index
                            focusedIndex = index
                        } else if hoveredIndex == index {
                            hoveredIndex = nil
                        }
                    }
                }
            }

            // Central Hub
            centralHubView
        }
    }

    // MARK: - Central Hub View
    private var centralHubView: some View {
        let activeIndex = hoveredIndex ?? focusedIndex
        let activeSegment = (activeIndex >= 0 && activeIndex < segments.count) ? segments[activeIndex] : nil

        return ZStack {
            // Center background disc
            Circle()
                .fill(ShiftKitColors.warmIvory)
                .frame(width: geometry.centerHubRadius * 2, height: geometry.centerHubRadius * 2)
                .overlay(
                    Circle()
                        .stroke(ShiftKitColors.sandBeige, lineWidth: 2)
                )
                .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.08), radius: 4, x: 0, y: 2)

            VStack(spacing: 3) {
                // Async file thumbnail or native icon
                FilePreviewView(file: file, size: 40)

                // Filename
                Text(file.fileName)
                    .font(ShiftKitTypography.captionBold)
                    .foregroundColor(ShiftKitColors.charcoalBrown)
                    .lineLimit(1)
                    .frame(maxWidth: geometry.centerHubRadius * 2 - 14)

                // Dynamic Action or File Info Prompt
                if let active = activeSegment {
                    HStack(spacing: 3) {
                        Text(active.title)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(ShiftKitColors.softTerracotta)
                        Text("(\(active.shortcutKey))")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(ShiftKitColors.textMuted)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(ShiftKitColors.warmPeach.opacity(0.5))
                    .clipShape(Capsule())
                } else {
                    Text(file.metadata.formattedSize)
                        .font(ShiftKitTypography.code)
                        .foregroundColor(ShiftKitColors.textMuted)
                }
            }
        }
    }

    // MARK: - Actions & Focus Navigation
    private func moveFocus(step: Int) {
        guard !segments.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.14)) {
            var next = (focusedIndex + step) % segments.count
            if next < 0 { next += segments.count }
            focusedIndex = next
            hoveredIndex = nil
        }
    }

    private func activateFocused() {
        guard focusedIndex >= 0 && focusedIndex < segments.count else { return }
        let segment = segments[focusedIndex]
        guard segment.isEnabled else { return }
        handleSegmentSelected(segment)
    }

    private func handleSegmentSelected(_ segment: RadialSegmentItem) {
        if !segment.subActions.isEmpty {
            withAnimation(.easeInOut(duration: 0.15)) {
                activeSubmenuSegment = segment
            }
        } else {
            // Direct action
            let fallbackAction = ConversionAction(
                id: segment.id,
                title: segment.title,
                subtitle: segment.subtitle,
                systemIcon: segment.systemIcon,
                category: segment.category
            )
            onSelectAction(fallbackAction)
        }
    }

    private func handleEscape() {
        if activeSubmenuSegment != nil {
            withAnimation(.easeInOut(duration: 0.15)) {
                activeSubmenuSegment = nil
            }
        } else {
            onDismiss()
        }
    }
}
