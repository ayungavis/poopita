import DesignSystem
import SwiftUI

struct TodayWeekStripView: View {
    let weekDays: [TodayWeekDayViewData]
    let selectDay: (String) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownIndex: Int?

    private var selectedIndex: Int? {
        weekDays.firstIndex(where: \.isSelected)
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekDays.enumerated()), id: \.element.id) { index, item in
                dayButton(item, isShown: index == (shownIndex ?? selectedIndex))
            }
        }
        .background(alignment: .leading) {
            if let index = shownIndex ?? selectedIndex {
                GeometryReader { proxy in
                    let cellWidth = proxy.size.width / CGFloat(max(weekDays.count, 1))
                    Capsule()
                        .fill(AppColor.ink)
                        .frame(width: cellWidth)
                        .offset(x: cellWidth * CGFloat(index))
                }
            }
        }
        .onChange(of: selectedIndex) { _, index in
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) {
                shownIndex = index
            }
        }
        .sensoryFeedback(.selection, trigger: selectedIndex)
    }

    private func dayButton(_ item: TodayWeekDayViewData, isShown: Bool) -> some View {
        Button {
            selectDay(item.dayID)
        } label: {
            VStack(spacing: Spacing.xs) {
                Text(verbatim: item.weekdaySymbol)
                    .font(AppFont.caption)
                    .foregroundStyle(isShown ? AppColor.onInk : AppColor.textSecondary)
                Text(verbatim: item.dayNumber)
                    .font(AppFont.title.weight(.regular))
                    .foregroundStyle(numberColor(item, isShown: isShown))
                DayMarkView(mark: item.mark, isSelected: isShown)
                    .frame(height: Spacing.sm)
            }
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
            .background {
                if item.isToday {
                    Capsule().strokeBorder(AppColor.ink, lineWidth: Spacing.borderWidth)
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

    private func numberColor(_ item: TodayWeekDayViewData, isShown: Bool) -> Color {
        if isShown {
            AppColor.onInk
        } else if item.mark == .future {
            AppColor.marker
        } else {
            AppColor.textPrimary
        }
    }
}
