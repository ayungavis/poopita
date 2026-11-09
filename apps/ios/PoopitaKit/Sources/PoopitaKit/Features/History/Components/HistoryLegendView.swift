import DesignSystem
import SwiftUI

struct HistoryLegendView: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.lg) { items }
            VStack(alignment: .leading, spacing: Spacing.sm) { items }
        }
        .font(AppFont.caption)
        .foregroundStyle(AppColor.textSecondary)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var items: some View {
        item("history.legend.logs") { DayTileSwatchView() }
        item("history.legend.noPoop") { DayMarkView(mark: .noPoop, isSelected: false) }
        item("history.legend.unrecorded") { DayMarkView(mark: .unrecorded, isSelected: false) }
    }

    private func item(_ title: LocalizedStringKey, @ViewBuilder swatch: () -> some View) -> some View {
        HStack(spacing: Spacing.xs) {
            swatch()
                .accessibilityHidden(true)
            Text(title, bundle: .module)
                .fixedSize()
        }
    }
}
