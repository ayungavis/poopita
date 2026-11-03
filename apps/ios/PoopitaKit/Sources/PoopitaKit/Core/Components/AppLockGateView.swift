import DesignSystem
import SwiftUI

struct AppLockGateView<Content: View>: View {
    let appLock: AppLockModel
    let asksOnAppear: Bool
    @ViewBuilder let content: Content

    var body: some View {
        content
            .accessibilityHidden(appLock.isLocked)
            .allowsHitTesting(!appLock.isLocked)
            .overlay {
                if appLock.isLocked {
                    locked
                }
            }
    }

    private var locked: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: "lock")
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
                .frame(width: Spacing.xxl * 2, height: Spacing.xxl * 2)
                .background(AppColor.track, in: Circle())
                .accessibilityHidden(true)
            Text("settings.appLock.lockedTitle", bundle: .module)
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            PrimaryButtonView(Text("appLock.unlock \(appLock.methodName)", bundle: .module)) {
                Task { await appLock.unlock() }
            }
            Text("appLock.grace", bundle: .module)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { AppColor.background.ignoresSafeArea() }
        .task {
            if asksOnAppear {
                await appLock.unlock()
            }
        }
    }
}
