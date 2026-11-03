import DesignSystem
import SwiftUI

struct OnboardingHeroView<Badge: View>: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    @ViewBuilder let badge: Badge

    var body: some View {
        VStack(spacing: Spacing.lg) {
            badge
                .frame(width: Spacing.xxl * 2, height: Spacing.xxl * 2)
                .accessibilityHidden(true)
            Text(title, bundle: .module)
                .font(AppFont.largeTitle)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(message, bundle: .module)
                .foregroundStyle(AppColor.textSecondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }
}
