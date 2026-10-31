import DesignSystem
import SwiftUI

struct EntryTileGridView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let choices: [EntryChoiceViewData]
    let selected: String?
    let columns: Int
    let select: (String) -> Void

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: Spacing.sm) {
            ForEach(choices) { choice in
                let isSelected = selected == choice.id
                Button { select(choice.id) } label: {
                    tile(for: choice)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: choice.illustration == nil ? Spacing.touchTarget : Spacing.tileHeight
                        )
                        .padding(.vertical, Spacing.sm)
                        .foregroundStyle(isSelected ? AppColor.onInk : AppColor.textPrimary)
                        .background(isSelected ? AppColor.ink : AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
                        .contentShape(RoundedRectangle(cornerRadius: Spacing.md))
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: [choice.title, choice.detail].filter { !$0.isEmpty }.joined(separator: ", ")))
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .sensoryFeedback(.selection, trigger: selected)
    }

    private func tile(for choice: EntryChoiceViewData) -> some View {
        VStack(spacing: Spacing.xs) {
            if let illustration = choice.illustration {
                EntryIllustrationView(kind: illustration)
            }
            if let badge = choice.badge {
                Text(verbatim: badge).font(AppFont.caption.weight(.medium))
            } else if choice.illustration == nil {
                Text(verbatim: choice.title).font(AppFont.body).multilineTextAlignment(.center)
            }
        }
    }

    private var gridColumns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? min(columns, 2) : columns
        return Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: count)
    }
}
