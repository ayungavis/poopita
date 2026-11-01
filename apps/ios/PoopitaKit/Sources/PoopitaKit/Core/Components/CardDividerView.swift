import DesignSystem
import SwiftUI

struct CardDividerView: View {
    var body: some View {
        Rectangle()
            .fill(AppColor.hairline)
            .frame(height: Spacing.borderWidth)
            .accessibilityHidden(true)
    }
}
