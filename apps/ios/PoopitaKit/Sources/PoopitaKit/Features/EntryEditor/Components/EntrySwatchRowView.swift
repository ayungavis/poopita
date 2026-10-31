import DesignSystem
import SwiftUI

struct EntrySwatchRowView: View {
    let choices: [EntryChoiceViewData]
    let selected: String?
    let select: (String) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(choices) { choice in
                let isSelected = selected == choice.id
                Button { select(choice.id) } label: {
                    Circle()
                        .fill(swatch(for: choice.id))
                        .overlay { Circle().strokeBorder(AppColor.hairline, lineWidth: Spacing.borderWidth) }
                        .padding(isSelected ? Spacing.xs : 0)
                        .overlay {
                            if isSelected {
                                Circle().strokeBorder(AppColor.ink, lineWidth: Spacing.selectionWidth)
                            }
                        }
                        .frame(width: Spacing.swatch, height: Spacing.swatch)
                        .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: choice.title))
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .sensoryFeedback(.selection, trigger: selected)
    }

    private func swatch(for id: String) -> Color {
        switch id {
        case "pale": StoolSwatch.pale
        case "yellow": StoolSwatch.yellow
        case "tan": StoolSwatch.tan
        case "orange": StoolSwatch.orange
        case "brown": StoolSwatch.brown
        case "green": StoolSwatch.green
        case "black": StoolSwatch.black
        default: StoolSwatch.red
        }
    }
}
