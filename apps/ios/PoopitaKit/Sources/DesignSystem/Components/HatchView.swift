import SwiftUI

public struct HatchView: View {
    private let color: Color

    public init(color: Color = AppColor.hairline) {
        self.color = color
    }

    public var body: some View {
        Canvas { context, size in
            var path = Path()
            var start = -size.height
            while start < size.width {
                path.move(to: CGPoint(x: start, y: size.height))
                path.addLine(to: CGPoint(x: start + size.height, y: 0))
                start += Spacing.sm
            }
            context.stroke(path, with: .color(color), lineWidth: Spacing.borderWidth)
        }
        .accessibilityHidden(true)
    }
}
