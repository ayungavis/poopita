import DesignSystem
import SwiftUI

struct PatternsDistributionRowView: View {
    let title: String
    let count: Int
    let ratio: Double

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(verbatim: title)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textPrimary)
                .frame(width: Spacing.accessibleChoiceWidth / 2, alignment: .leading)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColor.textSecondary.opacity(0.15))
                    Capsule()
                        .fill(AppColor.accent)
                        .frame(width: max(0, proxy.size.width * CGFloat(ratio)))
                }
            }
            .frame(height: Spacing.sm)
            Text(verbatim: "\(count)")
                .font(AppFont.body.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
                .frame(minWidth: Spacing.xl, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "\(title): \(count)"))
    }
}
