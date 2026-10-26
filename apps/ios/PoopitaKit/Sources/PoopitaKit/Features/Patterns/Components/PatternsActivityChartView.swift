import Charts
import DesignSystem
import SwiftUI

struct PatternsActivityChartView: View {
    let data: PatternsViewData
    @Binding var selectedBucketID: String?
    @ScaledMetric(relativeTo: .body) private var chartHeight = Spacing.choiceHeight * 2

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("patterns.activity.title", bundle: .module)
                .font(AppFont.title)
                .accessibilityAddTraits(.isHeader)
            if data.range == .oneDay {
                timeline
                Text("patterns.chart.timeLocal", bundle: .module)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            } else {
                activity
                Text("patterns.chart.select", bundle: .module)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            if data.totalEntries == 0 {
                Text("patterns.chart.empty", bundle: .module)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding(Spacing.lg)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }

    private var activity: some View {
        Chart(data.activityBuckets) { bucket in
            BarMark(
                x: .value(String(localized: "patterns.chart.period", bundle: .module), bucket.id),
                y: .value(String(localized: "patterns.chart.entries", bundle: .module), bucket.count)
            )
            .foregroundStyle(AppColor.accent.opacity(selectedBucketID == nil || selectedBucketID == bucket.id ? 1 : 0.35))
            .accessibilityLabel(Text(verbatim: bucket.detailLabel))
            .accessibilityValue(Text(verbatim: bucket.count.formatted()))
            if bucket.count == 0 {
                PointMark(x: .value("period", bucket.id), y: .value("count", 0))
                    .symbol(bucket.coverage.unrecordedDays > 0 ? .cross : bucket.coverage.partialDays > 0 ? .diamond : .circle)
                    .foregroundStyle(AppColor.textSecondary)
                    .accessibilityLabel(Text(verbatim: bucket.detailLabel))
            }
            if selectedBucketID == bucket.id {
                RuleMark(x: .value("period", bucket.id))
                    .foregroundStyle(AppColor.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .chartYScale(domain: 0 ... max(1, data.activityBuckets.map(\.count).max() ?? 1))
        .chartXAxis {
            AxisMarks(values: axisIDs) { value in
                AxisTick()
                AxisValueLabel {
                    if let id = value.as(String.self), let bucket = data.activityBuckets.first(where: { $0.id == id }) {
                        Text(verbatim: bucket.label).font(AppFont.caption)
                    }
                }
            }
        }
        .chartXSelection(value: $selectedBucketID)
        .frame(height: chartHeight)
    }

    private var axisIDs: [String] {
        data.activityBuckets.enumerated().compactMap { index, bucket in
            let stride = data.range == .fourWeeks ? 7 : data.range == .oneYear ? 2 : 1
            return index.isMultiple(of: stride) || index == data.activityBuckets.count - 1 ? bucket.id : nil
        }
    }

    private var timeline: some View {
        Chart(data.timeline) { point in
            PointMark(
                x: .value(String(localized: "patterns.chart.time", bundle: .module), point.hour),
                y: .value("record", 1)
            )
            .foregroundStyle(AppColor.accent)
            .accessibilityLabel(Text(verbatim: point.timeLabel))
        }
        .chartXScale(domain: 0 ... 24)
        .chartYScale(domain: 0 ... 2)
        .chartYAxis(.hidden)
        .chartXAxis { AxisMarks(values: [0, 6, 12, 18, 24]) }
        .frame(height: chartHeight)
    }
}
