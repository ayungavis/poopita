import DesignSystem
import SwiftUI

struct TodayWeekStripView: View {
    let weekDays: [TodayWeekDayViewData]
    let selectDay: (String) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekDays) { item in
                dayButton(item)
            }
        }
    }

    private func dayButton(_ item: TodayWeekDayViewData) -> some View {
        Button {
            selectDay(item.dayID)
        } label: {
            VStack(spacing: Spacing.xs) {
                Text(verbatim: item.weekdaySymbol)
                    .font(AppFont.caption)
                    .foregroundStyle(item.isSelected ? AppColor.onInk : AppColor.textSecondary)
                Text(verbatim: item.dayNumber)
                    .font(AppFont.title.weight(.regular))
                    .foregroundStyle(numberColor(item))
                TodayDayMarkView(mark: item.mark, isSelected: item.isSelected)
                    .frame(height: Spacing.sm)
            }
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
            .background {
                if item.isSelected {
                    Capsule().fill(AppColor.ink)
                } else if item.isToday {
                    Capsule().stroke(AppColor.ink, lineWidth: Spacing.borderWidth)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(item.mark == .future)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: item.accessibilityLabel))
        .accessibilityAddTraits(item.isSelected ? .isSelected : [])
    }

    private func numberColor(_ item: TodayWeekDayViewData) -> Color {
        if item.isSelected {
            AppColor.onInk
        } else if item.mark == .future {
            AppColor.marker
        } else {
            AppColor.textPrimary
        }
    }
}
