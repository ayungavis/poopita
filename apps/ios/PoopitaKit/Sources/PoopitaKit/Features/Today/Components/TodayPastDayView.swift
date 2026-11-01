import DesignSystem
import SwiftUI

struct TodayPastDayView: View {
    let status: String
    let detail: String
    let logLabel: String
    let canConfirm: Bool
    let mark: TodayWeekDayViewData.Mark
    let log: () -> Void
    let confirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(spacing: Spacing.sm) {
                TodayDayMarkView(mark: mark, isSelected: false)
                    .frame(minWidth: Spacing.lg)
                Text(verbatim: status)
                    .font(AppFont.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(.horizontal, Spacing.md)
            .frame(minHeight: Spacing.chipHeight - Spacing.sm)
            .background(AppColor.track, in: Capsule())
            .accessibilityElement(children: .combine)
            Text(verbatim: detail)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.sm) { actions }
                    .fixedSize(horizontal: true, vertical: false)
                VStack(spacing: Spacing.sm) { actions }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }

    @ViewBuilder
    private var actions: some View {
        capsule(Text(verbatim: logLabel), foreground: AppColor.onInk, background: AppColor.ink, action: log)
        if canConfirm {
            capsule(
                Text("checkIn.completed", bundle: .module), foreground: AppColor.textPrimary,
                background: AppColor.track, action: confirm
            )
        }
    }

    private func capsule(_ title: Text, foreground: Color, background: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            title
                .lineLimit(1)
                .font(AppFont.body.weight(.semibold))
                .foregroundStyle(foreground)
                .padding(.horizontal, Spacing.lg)
                .frame(maxWidth: .infinity, minHeight: Spacing.buttonHeight)
                .background(background, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
