import DesignSystem
import SwiftUI

struct EntryChoiceGridView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let choices: [EntryChoiceViewData]
    let selected: String?
    let select: (String) -> Void

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(choices) { choice in
                Button { select(choice.id) } label: {
                    VStack(spacing: Spacing.xs) {
                        if let illustration = choice.illustration {
                            EntryIllustrationView(kind: illustration)
                        }
                        Text(verbatim: choice.title).font(AppFont.caption.weight(.semibold))
                        if !choice.detail.isEmpty {
                            Text(verbatim: choice.detail).font(AppFont.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: Spacing.choiceHeight)
                    .padding(Spacing.xs)
                    .foregroundStyle(AppColor.textPrimary)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
                    .overlay {
                        RoundedRectangle(cornerRadius: Spacing.md)
                            .stroke(selected == choice.id ? AppColor.accent : AppColor.textSecondary,
                                    lineWidth: Spacing.borderWidth)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if selected == choice.id {
                        Image(systemName: "checkmark.circle.fill")
                            .font(AppFont.caption).foregroundStyle(AppColor.accent)
                            .padding(Spacing.xs).accessibilityHidden(true)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: [choice.title, choice.detail].filter { !$0.isEmpty }.joined(separator: ", ")))
                .accessibilityAddTraits(selected == choice.id ? .isSelected : [])
            }
        }
    }

    private var columns: [GridItem] {
        let width = dynamicTypeSize.isAccessibilitySize ? Spacing.accessibleChoiceWidth : Spacing.choiceWidth
        return [GridItem(.adaptive(minimum: width), spacing: Spacing.sm)]
    }
}
