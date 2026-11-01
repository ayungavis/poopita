import DesignSystem
import SwiftUI

struct InsightsFrequencyView: View {
    let viewModel: InsightsViewModel

    var body: some View {
        Group {
            if case let .loaded(data) = viewModel.state {
                content(data)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(AppColor.background)
        .navigationTitle(Text("insights.frequency", bundle: .module))
        .largeTitle()
    }

    private func content(_ data: InsightsViewData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                InsightsPeriodPickerView(selection: data.period, select: viewModel.select)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(verbatim: data.frequency.average)
                        .font(AppFont.display)
                        .foregroundStyle(AppColor.textPrimary)
                        .contentTransition(.numericText())
                    Text("insights.average", bundle: .module)
                        .font(AppFont.body.weight(.medium))
                    Text(verbatim: data.frequency.basis)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .padding(.top, Spacing.md)
                InsightsBarChartView(bars: data.frequency.bars)
                Text(verbatim: data.frequency.breakdownTitle)
                    .font(AppFont.caption.weight(.medium))
                    .foregroundStyle(AppColor.textSecondary)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, -Spacing.sm)
                CardSectionView(nil) {
                    ForEach(data.frequency.breakdown) { row in
                        if row.id != data.frequency.breakdown.first?.id {
                            CardDividerView()
                        }
                        breakdownRow(row)
                    }
                }
                Text("insights.method", bundle: .module)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
            .animation(.easeInOut(duration: 0.2), value: data)
        }
    }

    private func breakdownRow(_ row: InsightsBreakdownViewData) -> some View {
        HStack(spacing: Spacing.sm) {
            if let mark = row.mark {
                DayMarkView(mark: mark, isSelected: false)
                    .frame(minWidth: Spacing.lg)
            }
            Text(verbatim: row.title)
                .foregroundStyle(row.mark == nil ? AppColor.textSecondary : AppColor.textPrimary)
            Spacer(minLength: Spacing.md)
            Text(verbatim: row.count)
                .foregroundStyle(AppColor.textSecondary)
        }
        .cardRow()
        .accessibilityElement(children: .combine)
    }
}

private extension View {
    func largeTitle() -> some View {
        #if os(iOS)
            navigationBarTitleDisplayMode(.large)
        #else
            self
        #endif
    }
}
