import DesignSystem
import SwiftUI

struct InsightsDayCellView: View {
    let cell: InsightsDayCellViewData
    let isSelected: Bool

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(verbatim: cell.weekday)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
            Text(verbatim: cell.number)
                .font(AppFont.title.weight(.regular))
                .foregroundStyle(numberColor)
                .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
                .overlay(alignment: .bottom) {
                    DayMarkView(mark: cell.mark, isSelected: isSelected)
                        .frame(height: Spacing.sm)
                        .offset(y: Spacing.xs)
                }
                .padding(.bottom, Spacing.sm)
                .background {
                    let shape = RoundedRectangle(cornerRadius: Spacing.lg)
                    if isSelected {
                        shape.fill(AppColor.ink)
                    } else if cell.isToday {
                        shape.strokeBorder(AppColor.ink, lineWidth: Spacing.borderWidth)
                    }
                }
        }
        .accessibilityHidden(true)
    }

    private var numberColor: Color {
        if isSelected {
            AppColor.onInk
        } else if cell.mark == .future {
            AppColor.marker
        } else {
            AppColor.textPrimary
        }
    }
}
