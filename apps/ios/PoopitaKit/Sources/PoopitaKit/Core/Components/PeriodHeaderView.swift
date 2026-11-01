import DesignSystem
import SwiftUI

struct PeriodHeaderView: View {
    let title: String
    let detail: String?
    let accessibilityLabel: String
    let canMoveNext: Bool
    let move: (Int) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) { labels }
                VStack(alignment: .leading, spacing: 0) { labels }
            }
            .contentTransition(.opacity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: accessibilityLabel))
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.sm)
            stepButton("chevron.left", label: "period.previous", isEnabled: true) { move(-1) }
            stepButton("chevron.right", label: "period.next", isEnabled: canMoveNext) { move(1) }
        }
        .animation(.easeInOut(duration: 0.2), value: accessibilityLabel)
    }

    @ViewBuilder
    private var labels: some View {
        Text(verbatim: title)
            .font(AppFont.largeTitle)
            .foregroundStyle(AppColor.textPrimary)
            .lineLimit(1)
        if let detail {
            Text(verbatim: detail)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
        }
    }

    private func stepButton(
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
