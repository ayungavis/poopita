import DesignSystem
import SwiftUI

struct InsightsTypeRowView: View {
    let type: InsightsTypeViewData

    var body: some View {
        HStack(spacing: Spacing.md) {
            Group {
                if let illustration = type.illustration {
                    EntryIllustrationView(kind: illustration)
                } else {
                    Color.clear
                }
            }
            .frame(width: Spacing.illustrationWidth)
            .foregroundStyle(AppColor.textPrimary)
            VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                Text(verbatim: type.title)
                Text(verbatim: type.days)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: Spacing.sm)
            Text(verbatim: type.count)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.vertical, Spacing.md)
        .cardRow()
        .accessibilityElement(children: .combine)
    }
}
