import SwiftUI

public struct DayTileSwatchView: View {
    public init() {}

    public var body: some View {
        RoundedRectangle(cornerRadius: Spacing.xs)
            .fill(AppColor.entry)
            .frame(width: Spacing.lg, height: Spacing.md)
            .accessibilityHidden(true)
    }
}
