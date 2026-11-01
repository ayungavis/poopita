import DesignSystem
import SwiftUI

struct HistoryMonthHeaderView: View {
    let data: HistoryViewData
    let move: (Int) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(verbatim: data.monthName)
                    .font(AppFont.largeTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text(verbatim: data.yearLabel)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .contentTransition(.opacity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: data.monthLabel))
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.sm)
            monthButton("chevron.left", label: "history.previousMonth", isEnabled: true) { move(-1) }
            monthButton("chevron.right", label: "history.nextMonth", isEnabled: data.canMoveNext) { move(1) }
        }
        .animation(.easeInOut(duration: 0.2), value: data.monthLabel)
    }

    private func monthButton(
        _ symbol: String, label: LocalizedStringKey, isEnabled: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(AppFont.caption.weight(.semibold))
                .foregroundStyle(isEnabled ? AppColor.textPrimary : AppColor.marker)
                .frame(width: Spacing.touchTarget, height: Spacing.touchTarget)
                .background(AppColor.track.opacity(isEnabled ? 1 : 0.5), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(Text(label, bundle: .module))
    }
}
