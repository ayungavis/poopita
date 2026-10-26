import DesignSystem
import SwiftUI

struct PatternsContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let viewModel: PatternsViewModel
    let data: PatternsViewData
    @State private var selectedBucketID: String?
    @State private var selectedDayID: String?

    private var selectedBucket: PatternsActivityBucketViewData? {
        data.activityBuckets.first(where: { $0.id == selectedBucketID }) ?? data.activityBuckets.last
    }

    private var visibleDays: [PatternsDayDetailViewData] {
        guard data.range == .oneYear else { return data.dayDetails }
        guard let selectedBucket else { return [] }
        let ids = Set(selectedBucket.dayIDs)
        return data.dayDetails.filter { ids.contains($0.dayID) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xl) {
                rangePicker
                summary
                PatternsActivityChartView(data: data, selectedBucketID: $selectedBucketID)
                bucketSelector
                coverage(data.coverage)
                PatternsAnalyticsSectionsView(data: data)
                PatternsDayDetailSectionView(days: visibleDays, selectedDayID: $selectedDayID)
            }
            .padding(Spacing.lg)
        }
        .animation(reduceMotion ? nil : .easeInOut, value: data.range)
        .onChange(of: data.range) { _, _ in
            selectedBucketID = nil
            selectedDayID = nil
        }
        .onChange(of: selectedBucketID) { _, _ in selectedDayID = selectedBucket?.dayIDs.last }
        .onChange(of: selectedDayID) { _, dayID in
            if data.range != .oneYear, let dayID {
                selectedBucketID = data.activityBuckets.first { $0.dayIDs.contains(dayID) }?.id
            }
        }
    }

    private var rangePicker: some View {
        Picker(selection: Binding(get: { data.range }, set: viewModel.selectRange)) {
            ForEach(PatternsRange.allCases, id: \.self) { range in
                Text(LocalizedStringKey(range.displayKey), bundle: .module)
                    .tag(range)
                    .accessibilityLabel(Text(LocalizedStringKey(range.displayKey + ".accessibility"), bundle: .module))
            }
        } label: { Text("patterns.chart.period", bundle: .module) }
            .pickerStyle(.segmented)
            .frame(minHeight: Spacing.touchTarget)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(verbatim: data.dateRangeLabel)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
            Text(verbatim: data.totalEntries.formatted())
                .font(AppFont.largeTitle)
                .monospacedDigit()
            Text("patterns.dashboard.entries", bundle: .module).font(AppFont.body)
            Text("patterns.dashboard.context", bundle: .module)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var bucketSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Picker(selection: Binding(get: { selectedBucket?.id ?? "" }, set: { selectedBucketID = $0 })) {
                ForEach(data.activityBuckets) { bucket in Text(verbatim: bucket.detailLabel).tag(bucket.id) }
            } label: { Text("patterns.chart.period", bundle: .module) }
                .pickerStyle(.menu)
            if let selectedBucket {
                Text(verbatim: selectedBucket.detailLabel).font(AppFont.body.weight(.semibold))
                Text("patterns.status.logged \(selectedBucket.count)", bundle: .module)
                if selectedBucket.isPartial {
                    Text("patterns.chart.partial", bundle: .module).foregroundStyle(AppColor.textSecondary)
                }
                if data.range == .oneYear {
                    coverageRows(selectedBucket.coverage)
                }
            }
        }
        .font(AppFont.caption)
    }

    private func coverage(_ values: PatternsCoverageViewData) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("patterns.coverage.title", bundle: .module).font(AppFont.title).accessibilityAddTraits(.isHeader)
            coverageRows(values)
            Text("patterns.coverage.detail", bundle: .module)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(Spacing.lg)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }

    private func coverageRows(_ values: PatternsCoverageViewData) -> some View {
        let columns = Array(repeating: GridItem(.flexible()), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2)
        return LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.md) {
            coverageValue("patterns.coverage.logged", count: values.loggedDays, symbol: "circle.fill")
            coverageValue("patterns.coverage.confirmed", count: values.confirmedNoPoopDays, symbol: "circle")
            coverageValue("patterns.coverage.partial", count: values.partialDays, symbol: "diamond.fill")
            coverageValue("patterns.coverage.unknown", count: values.unrecordedDays, symbol: "minus")
        }
    }

    private func coverageValue(_ key: LocalizedStringKey, count: Int, symbol: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: symbol).foregroundStyle(AppColor.accent).accessibilityHidden(true)
            Text(verbatim: count.formatted()).font(AppFont.body.weight(.semibold)).monospacedDigit()
            Text(key, bundle: .module).font(AppFont.caption)
        }
        .accessibilityElement(children: .combine)
    }
}
