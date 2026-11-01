import DesignSystem
import SwiftUI

struct InsightsBubbleView: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(AppFont.caption.weight(.medium))
            .foregroundStyle(AppColor.onInk)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs + Spacing.xs / 2)
            .background(AppColor.ink, in: RoundedRectangle(cornerRadius: Spacing.sm))
            .fixedSize()
            .accessibilityHidden(true)
    }

    static func alignment(at index: Int, of count: Int) -> Alignment {
        switch index {
        case 0: .topLeading
        case count - 1: .topTrailing
        default: .top
        }
    }
}
