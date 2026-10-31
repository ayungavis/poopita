import DesignSystem
import SwiftUI

struct EntrySuggestionChipsView: View {
    let suggestions: [EntryChoiceViewData]
    let isAdded: (String) -> Bool
    let toggle: (String) -> Void

    var body: some View {
        ChipFlowLayout(spacing: Spacing.sm) {
            ForEach(suggestions) { suggestion in
                let added = isAdded(suggestion.title)
                Button { toggle(suggestion.title) } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: added ? "checkmark" : "plus").font(AppFont.caption).accessibilityHidden(true)
                        Text(verbatim: suggestion.title).font(AppFont.body)
                    }
                    .padding(.horizontal, Spacing.md)
                    .frame(minHeight: Spacing.chipHeight)
                    .foregroundStyle(added ? AppColor.onInk : AppColor.textPrimary)
                    .background(added ? AppColor.ink : AppColor.track, in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(added ? [.isButton, .isSelected] : .isButton)
            }
        }
    }
}

private struct ChipFlowLayout: Layout {
    private struct Row {
        var indices: [Int]
        var width: CGFloat
        var height: CGFloat
    }

    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        var top = bounds.minY
        for row in arrange(subviews, width: bounds.width) {
            var leading = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: leading, y: top), proposal: ProposedViewSize(size))
                leading += size.width + spacing
            }
            top += row.height + spacing
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if let last = rows.last, last.width + spacing + size.width <= width {
                rows[rows.count - 1] = Row(
                    indices: last.indices + [index], width: last.width + spacing + size.width,
                    height: max(last.height, size.height)
                )
            } else {
                rows.append(Row(indices: [index], width: size.width, height: size.height))
            }
        }
        return rows
    }
}
