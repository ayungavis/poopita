import DesignSystem
import SwiftUI

struct EntryRepeatButtonView: View {
    let summary: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "arrow.clockwise")
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(AppColor.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                    Text("entry.repeat", bundle: .module)
                        .font(AppFont.body.weight(.semibold))
                        .foregroundStyle(AppColor.textPrimary)
                    Text(verbatim: summary)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: Spacing.tileHeight, alignment: .leading)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
            .contentShape(RoundedRectangle(cornerRadius: Spacing.md))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("entry.repeat.hint", bundle: .module))
    }
}
