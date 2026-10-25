import DesignSystem
import SwiftUI

struct TodayWeekStripView: View {
    let weekDays: [TodayWeekDayViewData]
    let selectDay: (String) -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(weekDays) { item in
                dayButton(item)
            }
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.sm)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }

    private func dayButton(_ item: TodayWeekDayViewData) -> some View {
        Button {
            selectDay(item.dayID)
        } label: {
            VStack(spacing: Spacing.xs) {
                Text(verbatim: item.weekdaySymbol)
                    .font(AppFont.caption)
                    .foregroundStyle(item.isSelected ? AppColor.accent : AppColor.textSecondary)
                Text(verbatim: item.dayNumber)
                    .font(AppFont.body.weight(item.isSelected ? .semibold : .regular))
                    .foregroundStyle(item.isSelected ? AppColor.accent : AppColor.textPrimary)
                marker(item)
                    .frame(width: Spacing.xs, height: Spacing.xs)
            }
            .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
            .background(
                item.isSelected ? AppColor.accent.opacity(0.15) : .clear,
                in: RoundedRectangle(cornerRadius: Spacing.md)
            )
            .overlay {
                RoundedRectangle(cornerRadius: Spacing.md)
                    .stroke(item.isSelected ? AppColor.accent : .clear, lineWidth: Spacing.borderWidth)
            }
            .overlay(alignment: .bottom) {
                if item.isToday {
                    Capsule()
                        .fill(AppColor.accent)
                        .frame(width: Spacing.md, height: Spacing.borderWidth * 2)
                        .offset(y: Spacing.xs / 2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: item.accessibilityLabel))
        .accessibilityAddTraits(item.isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func marker(_ item: TodayWeekDayViewData) -> some View {
        if item.hasEntries {
            Circle().fill(AppColor.accent)
        } else if item.isConfirmedNoPoop {
            Circle().stroke(AppColor.accent, lineWidth: Spacing.borderWidth)
        } else if item.isPartialCheckIn {
            Image(systemName: "diamond.fill")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.accent)
        } else {
            Color.clear
        }
    }
}
