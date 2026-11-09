import SwiftUI

public struct DayTileSwatchView: View {
    public init() {}

    public var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(0 ..< 2, id: \.self) { _ in
                Circle().fill(AppColor.accent)
                    .frame(width: Spacing.xs, height: Spacing.xs)
            }
        }
        .frame(width: Spacing.lg + Spacing.xs, height: Spacing.md)
        .background(AppColor.entry, in: RoundedRectangle(cornerRadius: Spacing.xs))
        .accessibilityHidden(true)
    }
}
