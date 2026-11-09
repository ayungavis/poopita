import DesignSystem
import SwiftUI

struct HistoryCalendarView: View {
    let data: HistoryCalendarViewData
    let select: (String) -> Void
    @Environment(\.colorSchemeContrast) private var contrast

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 7)
    private let tile = RoundedRectangle(cornerRadius: Spacing.md)

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
        Button { select(item.dayID) } label: {
            VStack(spacing: Spacing.xs) {
                Text(verbatim: item.number)
                    .font(AppFont.title.weight(.regular))
                    .foregroundStyle(numberColor(item))
                    .padding(.horizontal, Spacing.xs)
                    .background {
                        if item.mark == .unrecorded, !item.isSelected {
                            RoundedRectangle(cornerRadius: Spacing.sm).fill(AppColor.background)
                        }
                    }
                DayMarkView(mark: item.mark, isSelected: item.isSelected, isOnTile: true)
                    .frame(height: Spacing.sm)
            }
            .frame(maxWidth: .infinity, minHeight: Spacing.buttonHeight)
            .background { background(item) }
            .overlay {
                if item.isToday, !item.isSelected {
                    tile.strokeBorder(AppColor.ink, lineWidth: Spacing.borderWidth)
                }
            }
            .contentShape(tile)
        }
        .buttonStyle(.plain)
        .disabled(item.mark == .future)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: item.accessibilityLabel))
        .accessibilityAddTraits(item.isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func background(_ item: HistoryDayViewData) -> some View {
        if item.isSelected {
            tile.fill(AppColor.ink)
        } else {
            switch item.mark {
            case .logs:
                tile.fill(AppColor.entry)
                    .overlay {
                        if contrast == .increased {
                            tile.strokeBorder(AppColor.marker, lineWidth: Spacing.borderWidth)
                        }
                    }
            case .unrecorded:
                HatchView(color: AppColor.marker)
                    .clipShape(tile)
                    .overlay { tile.strokeBorder(AppColor.marker, lineWidth: Spacing.borderWidth) }
            case .noPoop, .untracked, .future, .open:
                EmptyView()
            }
        }
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
