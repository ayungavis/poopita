import DesignSystem
import SwiftUI

struct AppLockOfferView: View {
    let appLock: AppLockModel

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "lock")
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
                .frame(width: Spacing.xxl * 2, height: Spacing.xxl * 2)
                .background(AppColor.track, in: Circle())
                .accessibilityHidden(true)
            Text("appLock.offer.title", bundle: .module)
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("appLock.offer.message \(appLock.methodName)", bundle: .module)
                .foregroundStyle(AppColor.textSecondary)
            PrimaryButtonView(Text("appLock.offer.turnOn \(appLock.methodName)", bundle: .module)) {
                Task { await appLock.acceptOffer() }
            }
            .padding(.top, Spacing.sm)
            Button(action: appLock.declineOffer) {
                Text("appLock.offer.notNow", bundle: .module)
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(AppColor.accent)
                    .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .font(AppFont.body)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.sm)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppColor.background)
    }
}
