import SwiftUI

// MARK: - Action Submenu & Format Catalog
public struct ActionSubmenuView: View {
    public let segment: RadialSegmentItem
    public let file: InspectedFile
    public let onSelectAction: (ConversionAction) -> Void
    public let onBack: () -> Void

    @State private var searchQuery: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var isSearchFieldFocused: Bool

    public init(
        segment: RadialSegmentItem,
        file: InspectedFile,
        onSelectAction: @escaping (ConversionAction) -> Void,
        onBack: @escaping () -> Void
    ) {
        self.segment = segment
        self.file = file
        self.onSelectAction = onSelectAction
        self.onBack = onBack
    }

    private var filteredActions: [ConversionAction] {
        if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            return segment.subActions
        }
        let q = searchQuery.lowercased().trimmingCharacters(in: .whitespaces)
        return segment.subActions.filter { action in
            action.title.lowercased().contains(q) ||
            action.subtitle.lowercased().contains(q) ||
            (action.targetFormat?.lowercased().contains(q) ?? false) ||
            (action.badgeTag?.lowercased().contains(q) ?? false)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 8) {
                Button {
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                        Text("Back")
                            .font(ShiftKitTypography.captionBold)
                    }
                    .foregroundColor(ShiftKitColors.charcoalBrown)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ShiftKitColors.softCream)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ShiftKitColors.sandBeige, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])

                Text(segment.title)
                    .font(ShiftKitTypography.headline)
                    .foregroundColor(ShiftKitColors.charcoalBrown)

                Spacer()

                ShiftKitPill(
                    "\(filteredActions.count) options",
                    icon: nil,
                    tint: ShiftKitColors.deepOlive,
                    background: ShiftKitColors.softCream
                )
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Search Bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(ShiftKitColors.charcoalBrown.opacity(0.5))

                TextField("Search format or operation...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(ShiftKitTypography.body)
                    .focused($isSearchFieldFocused)

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(ShiftKitColors.sandBeige)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(ShiftKitColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ShiftKitColors.sandBeige, lineWidth: 1)
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            Divider()
                .overlay(ShiftKitColors.border)

            // Scrollable Action List
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 4) {
                    if filteredActions.isEmpty {
                        VStack(spacing: 4) {
                            Text("No matching formats found")
                                .font(ShiftKitTypography.subheadline)
                                .foregroundColor(ShiftKitColors.charcoalBrown)
                            Text("Try searching for png, webp, mp4, compress, or trim")
                                .font(ShiftKitTypography.caption)
                                .foregroundColor(ShiftKitColors.textMuted)
                        }
                        .padding(.vertical, 24)
                    } else {
                        ForEach(Array(filteredActions.enumerated()), id: \.element.id) { idx, action in
                            let isSelected = selectedIndex == idx

                            Button {
                                onSelectAction(action)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: action.systemIcon)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(isSelected ? ShiftKitColors.charcoalBrown : ShiftKitColors.deepOlive)
                                        .frame(width: 24, height: 24)
                                        .background(isSelected ? ShiftKitColors.warmPeach : ShiftKitColors.softCream)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(action.title)
                                            .font(ShiftKitTypography.subheadline)
                                            .foregroundColor(ShiftKitColors.charcoalBrown)

                                        Text(action.subtitle)
                                            .font(ShiftKitTypography.caption)
                                            .foregroundColor(ShiftKitColors.textMuted)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    if let badge = action.badgeTag {
                                        Text(badge)
                                            .font(ShiftKitTypography.code)
                                            .foregroundColor(ShiftKitColors.deepOlive)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(ShiftKitColors.softCream)
                                            .clipShape(Capsule())
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(ShiftKitColors.charcoalBrown.opacity(0.4))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(
                                    isSelected
                                        ? ShiftKitColors.warmPeach.opacity(0.6)
                                        : ShiftKitColors.surface
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isSelected ? ShiftKitColors.softTerracotta : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 210)

            Divider()
                .overlay(ShiftKitColors.border)

            // Footer navigation hint
            HStack {
                Text("Esc: Return to Ring")
                    .font(ShiftKitTypography.caption)
                    .foregroundColor(ShiftKitColors.textMuted)

                Spacer()

                Text("Click or Enter to Execute")
                    .font(ShiftKitTypography.caption)
                    .foregroundColor(ShiftKitColors.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(ShiftKitColors.softCream.opacity(0.5))
        }
        .frame(width: 320, height: 320)
        .background(ShiftKitColors.warmIvory)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ShiftKitColors.sandBeige, lineWidth: 1.5)
        )
        .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.12), radius: 16, x: 0, y: 6)
    }
}
