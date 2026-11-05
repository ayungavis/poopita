import DesignSystem
import SwiftUI

struct TodayTopBarView: View {
    let data: TodayViewData?
    let isCompact: Bool
    let openSettings: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            if let data {
                TodayTitleView(monthLabel: data.monthLabel, title: data.title, isCompact: isCompact)
            }
            Spacer(minLength: 0)
            Button(action: openSettings) {
                AppIcon.settings
                    .resizable()
                    .scaledToFit()
                    .frame(width: Spacing.icon, height: Spacing.icon)
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: Spacing.touchTarget, height: Spacing.touchTarget)
                    .contentShape(Circle())
                    .glassEffect(.regular.interactive(), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("settings.title", bundle: .module))
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.xs)
        .background(AppColor.background)
    }
}
