import DesignSystem
import SwiftUI

struct OnboardingWelcomeView: View {
    var body: some View {
        VStack(spacing: Spacing.xl) {
            OnboardingHeroView(title: "onboarding.welcome.title", message: "onboarding.welcome.message") {
                Image("appIcon", bundle: .module)
                    .resizable()
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.lg))
            }
            CardSectionView(nil) {
                OnboardingRowView(title: "onboarding.welcome.device", detail: "onboarding.welcome.deviceDetail") {
                    symbol("lock")
                }
                OnboardingRowView(title: "onboarding.welcome.account", detail: "onboarding.welcome.accountDetail") {
                    symbol("person.slash")
                }
                OnboardingRowView(title: "onboarding.welcome.sharing", detail: "onboarding.welcome.sharingDetail") {
                    symbol("square.and.arrow.up")
                }
            }
        }
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(AppFont.body)
            .foregroundStyle(AppColor.textPrimary)
    }
}
