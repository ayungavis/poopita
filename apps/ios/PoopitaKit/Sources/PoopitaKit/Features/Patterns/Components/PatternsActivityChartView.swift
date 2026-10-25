import DesignSystem
import SwiftUI

struct PatternsActivityChartView: View {
    let activity: [PatternsDailyActivityViewData]
    let range: PatternsRange

    private let maxBarHeight: CGFloat = 64

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack(alignment: .bottom, spacing: range == .sevenDays ? Spacing.sm : Spacing.xs / 2) {
                ForEach(activity) { item in
                    dayColumn(item)
                }
            }
            .frame(maxWidth: .infinity, minHeight: maxBarHeight + Spacing.xl + Spacing.lg, alignment: .bottom)
            .padding(.vertical, Spacing.sm)

            if range == .thirtyDays, let first = activity.first, let last = activity.last {
                HStack {
                    Text(verbatim: first.dayID)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                    Text(verbatim: last.dayID)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("patterns.chart.legend1", bundle: .module)
                Text("patterns.chart.legend2", bundle: .module)
            }
            .font(AppFont.caption)
            .foregroundStyle(AppColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.lg)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }

    private func dayColumn(_ item: PatternsDailyActivityViewData) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(verbatim: item.statusMark)
                .font(AppFont.caption)
                .foregroundStyle(item.count > 0 ? AppColor.textPrimary : AppColor.textSecondary)
                .frame(height: Spacing.md)

            ZStack(alignment: .bottom) {
                Color.clear.frame(height: maxBarHeight)
                if item.count > 0 {
                    RoundedRectangle(cornerRadius: Spacing.xs)
                        .fill(AppColor.accent)
                        .frame(height: max(Spacing.sm, CGFloat(item.ratio) * maxBarHeight))
                } else {
                    emptyMark(item.status)
                        .frame(height: Spacing.xs)
                }
            }
            .frame(maxWidth: .infinity)

            if range == .sevenDays {
                Text(verbatim: item.label)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(height: Spacing.md)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: item.accessibilityLabel))
    }

    @ViewBuilder
    private func emptyMark(_ status: PatternsDayStatus) -> some View {
        switch status {
        case .confirmedNoPoop:
            Circle().stroke(AppColor.accent, lineWidth: Spacing.borderWidth)
        case .partialCheckIn:
            Image(systemName: "diamond.fill")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.accent)
        case .unrecorded, .logged:
            Capsule().fill(AppColor.textSecondary.opacity(0.3))
        }
    }
}
