import DesignSystem
import SwiftUI

struct InsightsPeriodPickerView: View {
    let selection: InsightsPeriod
    let select: (InsightsPeriod) -> Void
    @Namespace private var pill

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(InsightsPeriod.allCases, id: \.self) { period in
                let isSelected = period == selection
                Button { select(period) } label: {
                    Text(title(period), bundle: .module)
                        .font(AppFont.body.weight(isSelected ? .medium : .regular))
                        .foregroundStyle(isSelected ? AppColor.textPrimary : AppColor.textSecondary)
                        .padding(.horizontal, Spacing.lg)
                        .frame(minHeight: Spacing.touchTarget)
                        .background {
                            if isSelected {
                                Capsule().fill(AppColor.track).matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .animation(.snappy(duration: 0.25), value: selection)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func title(_ period: InsightsPeriod) -> LocalizedStringKey {
        switch period {
        case .week: "insights.period.week"
        case .month: "insights.period.month"
        case .year: "insights.period.year"
        }
    }
}
