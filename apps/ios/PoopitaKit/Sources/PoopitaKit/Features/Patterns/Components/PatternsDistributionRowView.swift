import DesignSystem
import SwiftUI

struct PatternsDistributionRowView: View {
    let title: String
    let count: Int
    let ratio: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
                Text(verbatim: title).font(AppFont.body)
                Spacer(minLength: Spacing.sm)
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text(verbatim: count.formatted()).font(AppFont.body.weight(.semibold))
                    Text(verbatim: ratio.formatted(.percent.precision(.fractionLength(0 ... 1))))
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .monospacedDigit()
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColor.textSecondary.opacity(0.15))
                    Capsule().fill(AppColor.accent)
                        .frame(width: proxy.size.width * min(1, max(0, ratio)))
                }
            }
            .frame(height: Spacing.sm)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}
