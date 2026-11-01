import DesignSystem
import SwiftUI

struct TodayHeaderView: View {
    let data: TodayViewData

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(verbatim: data.monthLabel)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                    Text(verbatim: data.title)
                        .font(AppFont.largeTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer()
                Text(verbatim: data.dayNumber)
                    .font(AppFont.display)
                    .foregroundStyle(AppColor.textPrimary)
                    .accessibilityHidden(true)
            }
        }
    }
}
