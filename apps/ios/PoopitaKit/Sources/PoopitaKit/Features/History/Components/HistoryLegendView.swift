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
        item(.logs(2), "history.legend.logs")
        item(.noPoop, "history.legend.noPoop")
        item(.unrecorded, "history.legend.unrecorded")
    }

    private func item(_ mark: DayMarkViewData, _ title: LocalizedStringKey) -> some View {
        HStack(spacing: Spacing.xs) {
            DayMarkView(mark: mark, isSelected: false)
                .accessibilityHidden(true)
            Text(title, bundle: .module)
                .fixedSize()
        }
    }
}
