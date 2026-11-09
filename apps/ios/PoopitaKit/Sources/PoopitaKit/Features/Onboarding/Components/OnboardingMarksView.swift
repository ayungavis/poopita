import DesignSystem
import SwiftUI

struct OnboardingMarksView: View {
    let days: [OnboardingDayViewData]

    var body: some View {
        VStack(spacing: Spacing.xl) {
            OnboardingHeroView(title: "onboarding.marks.title", message: "onboarding.marks.message") {
                OnboardingSymbolBadgeView(systemName: "calendar")
            }
            HStack(spacing: 0) {
                ForEach(days) { day in
                    VStack(spacing: Spacing.xs) {
                        Text(verbatim: day.weekdaySymbol)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textSecondary)
                        Text(verbatim: day.dayNumber)
                            .font(AppFont.title.weight(day.isToday ? .semibold : .regular))
                            .foregroundStyle(AppColor.textPrimary)
                        DayMarkView(mark: day.mark, isSelected: false)
                            .frame(height: Spacing.sm)
                    }
                    .padding(.vertical, Spacing.sm)
                    .frame(maxWidth: .infinity)
                    .background {
                        if day.isToday {
                            RoundedRectangle(cornerRadius: Spacing.md)
                                .strokeBorder(AppColor.ink, lineWidth: Spacing.borderWidth)
                                .padding(.horizontal, Spacing.sm)
                        }
                    }
                }
            }
            .accessibilityHidden(true)
            CardSectionView(nil) {
                OnboardingRowView(title: "history.legend.logs", detail: "onboarding.marks.logs") {
                    DayMarkView(mark: .logs(2), isSelected: false)
                }
                OnboardingRowView(title: "history.legend.noPoop", detail: "onboarding.marks.noPoop") {
                    DayMarkView(mark: .noPoop, isSelected: false)
                }
                OnboardingRowView(title: "history.legend.unrecorded", detail: "onboarding.marks.unrecorded") {
                    DayMarkView(mark: .unrecorded, isSelected: false)
                }
            }
        }
    }
}
