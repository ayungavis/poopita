import DesignSystem
import SwiftUI

struct TodayHeaderView: View {
    let data: TodayViewData
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text(verbatim: "poopita")
                    .font(AppFont.wordmark)
                    .foregroundStyle(AppColor.textPrimary)
                    .accessibilityHidden(true)
                Spacer()
                Button(action: openSettings) {
                    AppIcon.settings
                        .resizable()
                        .scaledToFit()
                        .frame(width: Spacing.icon, height: Spacing.icon)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(width: Spacing.touchTarget, height: Spacing.touchTarget)
                        .background(AppColor.track, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("settings.title", bundle: .module))
            }
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
