import DesignSystem
import SwiftUI

struct OnboardingProgressView: View {
    let index: Int
    let label: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(OnboardingViewData.Step.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue == index ? AppColor.ink : AppColor.hairline)
                    .frame(width: step.rawValue == index ? Spacing.xl - Spacing.xs : Spacing.sm, height: Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: label))
    }
}
