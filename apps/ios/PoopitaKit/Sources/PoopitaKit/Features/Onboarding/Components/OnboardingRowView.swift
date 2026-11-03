import DesignSystem
import SwiftUI

struct OnboardingRowView<Leading: View>: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    @ViewBuilder let leading: Leading

    var body: some View {
        HStack(spacing: Spacing.md) {
            leading
                .frame(width: Spacing.xxl + Spacing.xs, height: Spacing.xxl + Spacing.xs)
                .background(AppColor.background, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                Text(title, bundle: .module)
                    .font(AppFont.body.weight(.medium))
                    .foregroundStyle(AppColor.textPrimary)
                Text(detail, bundle: .module)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.md)
        .accessibilityElement(children: .combine)
    }
}
