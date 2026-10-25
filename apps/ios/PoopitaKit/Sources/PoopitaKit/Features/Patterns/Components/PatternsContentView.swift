import DesignSystem
import SwiftUI

struct PatternsContentView: View {
    let viewModel: PatternsViewModel
    let data: PatternsViewData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                rangePicker
                summarySection
                PatternsActivityChartView(activity: data.dailyActivity, range: data.range)
                timeOfDayCard
                consistencyCard
            }
            .padding(Spacing.lg)
        }
    }

    private var rangePicker: some View {
        HStack(spacing: Spacing.sm) {
            rangeButton(.sevenDays, titleKey: "patterns.range.sevenDays")
            rangeButton(.thirtyDays, titleKey: "patterns.range.thirtyDays")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rangeButton(_ range: PatternsRange, titleKey: LocalizedStringKey) -> some View {
        let isSelected = data.range == range
        return Button {
            viewModel.selectRange(range)
        } label: {
            Text(titleKey, bundle: .module)
                .font(AppFont.body.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AppColor.accent : AppColor.textPrimary)
                .padding(.horizontal, Spacing.lg)
                .frame(minHeight: Spacing.touchTarget)
                .background(
                    isSelected ? AppColor.accent.opacity(0.15) : AppColor.surface,
                    in: RoundedRectangle(cornerRadius: Spacing.md)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: Spacing.md)
                        .stroke(
                            isSelected ? AppColor.accent : AppColor.textSecondary.opacity(0.2),
                            lineWidth: Spacing.borderWidth
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(verbatim: "\(data.totalEntries)")
                .font(AppFont.largeTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text(verbatim: data.summaryLabel)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textPrimary)
            Text(verbatim: data.dateRangeLabel)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var timeOfDayCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("patterns.timeOfDay.title", bundle: .module)
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)

            if data.timeOfDay.hasEntries {
                VStack(spacing: Spacing.md) {
                    ForEach(data.timeOfDay.periods) { period in
                        PatternsDistributionRowView(
                            title: period.title,
                            count: period.count,
                            ratio: period.ratio
                        )
                    }
                }
            } else {
                Text("patterns.timeOfDay.empty", bundle: .module)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }

    private var consistencyCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("patterns.consistency.title", bundle: .module)
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)

            if data.consistency.hasEntries {
                VStack(spacing: Spacing.md) {
                    ForEach(data.consistency.items) { item in
                        PatternsDistributionRowView(
                            title: item.title,
                            count: item.count,
                            ratio: item.ratio
                        )
                    }
                }
                Text(verbatim: data.consistency.ratioLabel)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.top, Spacing.xs)
            } else {
                Text("patterns.consistency.empty", bundle: .module)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }
}
