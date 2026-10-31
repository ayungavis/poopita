import DesignSystem
import SwiftUI

struct TodayPastDayView: View {
    let status: String
    let detail: String
    let logLabel: String
    let canConfirm: Bool
    let log: () -> Void
    let confirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(verbatim: status)
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(verbatim: detail)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.sm) { actions }
                VStack(spacing: Spacing.sm) { actions }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }

    @ViewBuilder
    private var actions: some View {
        PrimaryButtonView(Text(verbatim: logLabel), action: log)
        if canConfirm {
            Button(action: confirm) {
                Text("checkIn.completed", bundle: .module)
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(.horizontal, Spacing.lg)
                    .frame(maxWidth: .infinity, minHeight: Spacing.buttonHeight)
                    .background(AppColor.track, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}
