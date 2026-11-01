import DesignSystem
import SwiftUI

struct HistoryCalendarView: View {
    let data: HistoryCalendarViewData
    let select: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.xs) {
            ForEach(Array(data.weekdays.enumerated()), id: \.offset) { weekday in
                Text(verbatim: weekday.element)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: Spacing.xl)
                    .accessibilityHidden(true)
            }
            ForEach(Array(data.days.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayButton(day)
                } else {
                    Color.clear.frame(height: Spacing.buttonHeight)
                        .accessibilityHidden(true)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: data.days.first { $0?.isSelected == true }??.dayID)
    }

    private func dayButton(_ item: HistoryDayViewData) -> some View {
        let shape = RoundedRectangle(cornerRadius: Spacing.lg)
        return Button { select(item.dayID) } label: {
            VStack(spacing: Spacing.xs) {
                Text(verbatim: item.number)
                    .font(AppFont.title.weight(.regular))
                    .foregroundStyle(numberColor(item))
                DayMarkView(mark: item.mark, isSelected: item.isSelected)
                    .frame(height: Spacing.sm)
            }
            .frame(maxWidth: .infinity, minHeight: Spacing.buttonHeight)
            .background {
                if item.isSelected {
                    shape.fill(AppColor.ink)
                } else if item.isToday {
                    shape.strokeBorder(AppColor.ink, lineWidth: Spacing.borderWidth)
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(item.mark == .future)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: item.accessibilityLabel))
        .accessibilityAddTraits(item.isSelected ? .isSelected : [])
    }

    private func numberColor(_ item: HistoryDayViewData) -> Color {
        if item.isSelected {
            AppColor.onInk
        } else if item.mark == .future {
            AppColor.marker
        } else {
            AppColor.textPrimary
        }
    }
}
