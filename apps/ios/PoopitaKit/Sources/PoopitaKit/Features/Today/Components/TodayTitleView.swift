import DesignSystem
import SwiftUI

struct TodayTitleView: View {
    let monthLabel: String
    let title: String
    let isCompact: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .leading) {
            Text(verbatim: "poopita")
                .font(AppFont.wordmark)
                .foregroundStyle(AppColor.textPrimary)
                .opacity(isCompact ? 0 : 1)
                .offset(y: isCompact && !reduceMotion ? -Spacing.sm : 0)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: monthLabel)
                    .contentTransition(.opacity)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                Text(verbatim: title)
                    .contentTransition(.opacity)
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
            }
            .opacity(isCompact ? 1 : 0)
            .offset(y: isCompact || reduceMotion ? 0 : Spacing.sm)
            .accessibilityElement(children: .combine)
            .accessibilityHidden(!isCompact)
        }
        .fixedSize()
        .animation(.snappy(duration: 0.25), value: isCompact)
        .animation(.easeInOut(duration: 0.2), value: title)
    }
}
