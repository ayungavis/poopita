import DesignSystem
import SwiftUI

struct InsightsComfortView: View {
    let rows: [InsightsComfortRowViewData]

    var body: some View {
        CardSectionView("insights.comfort.title") {
            ForEach(rows) { row in
                if row.id != rows.first?.id {
                    CardDividerView()
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.sm) {
                        Text(verbatim: row.label)
                        Spacer(minLength: Spacing.sm)
                        Text(verbatim: row.value).foregroundStyle(AppColor.textSecondary)
                    }
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(verbatim: row.label)
                        Text(verbatim: row.value).foregroundStyle(AppColor.textSecondary)
                    }
                    .padding(.vertical, Spacing.sm)
                }
                .cardRow()
                .accessibilityElement(children: .combine)
            }
        }
    }
}
