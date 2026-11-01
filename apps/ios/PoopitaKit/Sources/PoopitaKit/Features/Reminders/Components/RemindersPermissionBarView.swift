import DesignSystem
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

struct RemindersPermissionBarView: View {
    @Environment(\.openURL) private var openURL
    let isDenied: Bool
    let allow: () -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
            if isDenied {
                PrimaryButtonView(Text("reminders.openSettings", bundle: .module), action: openSettings)
                Text("reminders.denied", bundle: .module)
            } else {
                PrimaryButtonView(Text("reminders.allow", bundle: .module), action: allow)
                Text("reminders.allowCaption", bundle: .module)
            }
        }
        .font(AppFont.caption)
        .foregroundStyle(AppColor.textSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(AppColor.background)
        .overlay(alignment: .top) { CardDividerView() }
    }

    private func openSettings() {
        #if canImport(UIKit)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
        #endif
    }
}
