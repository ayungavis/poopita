import DesignSystem
import SwiftUI

struct PatternsAnalyticsSectionsView: View {
    let data: PatternsViewData

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            consistency
            PatternsObservationSectionView(title: "patterns.amount.title", detail: "patterns.amount.detail", data: data.amount)
            PatternsObservationSectionView(title: "patterns.effort.title", detail: "patterns.effort.detail", data: data.effort)
            timeOfDay
        }
    }

    private var consistency: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("patterns.consistency.title", bundle: .module).font(AppFont.title).accessibilityAddTraits(.isHeader)
            Text("patterns.consistency.detail", bundle: .module).font(AppFont.caption).foregroundStyle(AppColor.textSecondary)
            Text(
                "patterns.observation.recorded \(data.consistency.totalClassified), \(data.consistency.totalEntries)",
                bundle: .module
            )
            .font(AppFont.caption)
            if data.consistency.hasEntries {
                ForEach(data.consistency.items) { item in
                    PatternsDistributionRowView(title: item.title, count: item.count, ratio: item.ratio)
                }
            } else {
                Text("patterns.observation.empty", bundle: .module).foregroundStyle(AppColor.textSecondary)
            }
            Text(
                "patterns.observation.missing \(data.consistency.totalEntries - data.consistency.totalClassified)",
                bundle: .module
            )
            .font(AppFont.caption)
            .foregroundStyle(AppColor.textSecondary)
        }
        .padding(Spacing.lg)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }

    private var timeOfDay: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("patterns.timeOfDay.title", bundle: .module).font(AppFont.title).accessibilityAddTraits(.isHeader)
            Text("patterns.timeOfDay.detail", bundle: .module).font(AppFont.caption).foregroundStyle(AppColor.textSecondary)
            Text("patterns.observation.recorded \(data.timeOfDay.totalEntries), \(data.timeOfDay.totalEntries)", bundle: .module)
                .font(AppFont.caption)
            if data.timeOfDay.hasEntries {
                ForEach(data.timeOfDay.periods) { period in
                    PatternsDistributionRowView(title: period.title, count: period.count, ratio: period.ratio)
                }
            } else {
                Text("patterns.chart.empty", bundle: .module).foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding(Spacing.lg)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }
}
