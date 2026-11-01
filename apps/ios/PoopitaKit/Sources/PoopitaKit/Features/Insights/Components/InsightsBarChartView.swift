import DesignSystem
import SwiftUI

struct InsightsBarChartView: View {
    let bars: [InsightsBarViewData]
    @State private var selectedID: String?
    @ScaledMetric(relativeTo: .body) private var height = Spacing.barChartHeight

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(bars.enumerated()), id: \.element.id) { index, bar in
                    barView(bar, alignment: InsightsBubbleView.alignment(at: index, of: bars.count))
                        .zIndex(bar.id == selectedID ? 1 : 0)
                }
            }
            .frame(height: height)
            .padding(.top, Spacing.xl)
            .overlay(alignment: .bottom) {
                Rectangle().fill(AppColor.hairline).frame(height: Spacing.borderWidth)
            }
            HStack(spacing: 0) {
                ForEach(bars) { bar in
                    Button { toggle(bar.id) } label: {
                        if let cell = bar.cell {
                            InsightsDayCellView(cell: cell, isSelected: bar.id == selectedID)
                        } else {
                            Text(verbatim: bar.label ?? "")
                                .font(AppFont.caption)
                                .foregroundStyle(bar.id == selectedID ? AppColor.textPrimary : AppColor.textSecondary)
                                .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHidden(true)
                }
            }
        }
        .onChange(of: bars) { selectedID = nil }
        .sensoryFeedback(.selection, trigger: selectedID)
    }

    private func barView(_ bar: InsightsBarViewData, alignment: Alignment) -> some View {
        let isSelected = bar.id == selectedID
        let isThin = bars.count > 7
        return Button { toggle(bar.id) } label: {
            ZStack(alignment: .bottom) {
                Color.clear
                if bar.isUnrecorded {
                    HatchView(color: AppColor.marker.opacity(0.5))
                } else if bar.ratio > 0 {
                    RoundedRectangle(cornerRadius: isThin ? Spacing.xs : Spacing.sm)
                        .fill(isSelected ? AppColor.ink : AppColor.marker)
                        .frame(height: max(Spacing.sm, height * bar.ratio))
                }
            }
            .padding(.horizontal, isThin ? Spacing.xs : Spacing.md)
            .contentShape(Rectangle())
            .overlay(alignment: alignment) {
                if isSelected {
                    InsightsBubbleView(text: bar.summary)
                        .offset(y: bar.isUnrecorded ? -Spacing.xl : height * (1 - bar.ratio) - Spacing.xl)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: bar.summary))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func toggle(_ id: String) {
        selectedID = selectedID == id ? nil : id
    }
}
