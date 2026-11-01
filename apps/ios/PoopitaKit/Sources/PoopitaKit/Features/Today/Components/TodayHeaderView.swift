import DesignSystem
import SwiftUI

struct TodayHeaderView: View {
    let data: TodayViewData

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(verbatim: data.monthLabel)
                .contentTransition(.opacity)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
            Text(verbatim: data.title)
                .contentTransition(.opacity)
                .font(AppFont.largeTitle)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
        }
        .animation(.easeInOut(duration: 0.2), value: data.title)
    }
}
