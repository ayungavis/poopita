import DesignSystem
import SwiftUI

struct OnboardingSymbolBadgeView: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(AppFont.title)
            .foregroundStyle(AppColor.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.track, in: Circle())
    }
}
