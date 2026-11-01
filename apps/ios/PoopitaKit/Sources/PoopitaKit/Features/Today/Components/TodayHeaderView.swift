import DesignSystem
import SwiftUI

struct TodayHeaderView: View {
    let data: TodayViewData

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(verbatim: data.monthLabel)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
            Text(verbatim: data.title)
                .font(AppFont.largeTitle)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
        }
    }
}
