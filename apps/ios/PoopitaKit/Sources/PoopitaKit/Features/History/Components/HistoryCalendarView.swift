import DesignSystem
import SwiftUI

struct HistoryCalendarView: View {
    let data: HistoryCalendarViewData
    let selectedID: String
    let todayID: String
    let select: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.xs) {
            ForEach(Array(data.weekdays.enumerated()), id: \.offset) { weekday in
                Text(verbatim: weekday.element)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
                    .accessibilityHidden(true)
            }
            ForEach(Array(data.days.enumerated()), id: \.offset) { _, day in
                if let day {
                    dateButton(day)
                } else {
                    Color.clear.frame(height: Spacing.touchTarget)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private func dateButton(_ item: HistoryDayViewData) -> some View {
        let isSelected = item.dayID == selectedID
        let isToday = item.dayID == todayID
        let isFuture = item.dayID > todayID
        return Button { select(item.dayID) } label: {
            VStack(spacing: Spacing.xs) {
                Text(verbatim: item.number)
                    .font(AppFont.body.weight(isSelected ? .semibold : .regular))
                marker(item.status)
                    .frame(width: Spacing.xs, height: Spacing.xs)
            }
            .foregroundStyle(isFuture ? AppColor.textSecondary.opacity(0.4) : AppColor.textPrimary)
            .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
            .background(isSelected ? AppColor.accent.opacity(0.15) : .clear,
                        in: RoundedRectangle(cornerRadius: Spacing.sm))
            .overlay {
                RoundedRectangle(cornerRadius: Spacing.sm)
                    .stroke(isSelected ? AppColor.accent : .clear, lineWidth: Spacing.borderWidth)
            }
            .overlay(alignment: .bottom) {
                if isToday {
                    Capsule().fill(AppColor.accent).frame(width: Spacing.md, height: Spacing.borderWidth)
                        .offset(y: Spacing.xs)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel(Text(verbatim: item.accessibilityLabel))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func marker(_ status: HistoryDayViewData.Status) -> some View {
        switch status {
        case .logged:
            Circle().fill(AppColor.accent)
        case .completed:
            Circle().stroke(AppColor.accent, lineWidth: Spacing.borderWidth)
        case .partial:
            Image(systemName: "diamond.fill").font(AppFont.caption).foregroundStyle(AppColor.accent)
        case .unrecorded:
            Capsule().fill(AppColor.textSecondary).frame(width: Spacing.sm, height: Spacing.borderWidth)
        }
    }
}
