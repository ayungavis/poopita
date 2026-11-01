import SwiftUI

public struct PrimaryButtonView: View {
    private let title: Text
    private let action: () -> Void

    public init(_ title: Text, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            title
                .lineLimit(1)
                .font(AppFont.body.weight(.semibold))
                .foregroundStyle(AppColor.onInk)
                .frame(maxWidth: .infinity, minHeight: Spacing.buttonHeight)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(AppColor.ink)
    }
}
