import SwiftUI

public struct AppTabBarItem<Value: Hashable>: Identifiable {
    public let value: Value
    public let title: Text
    public let icon: Image

    public var id: Value {
        value
    }

    public init(_ value: Value, title: Text, icon: Image) {
        self.value = value
        self.title = title
        self.icon = icon
    }
}

public struct AppTabBarView<Value: Hashable>: View {
    @Binding private var selection: Value
    private let items: [AppTabBarItem<Value>]
    private let actionTitle: Text
    private let action: () -> Void
    @ScaledMetric(relativeTo: .footnote) private var iconSize = Spacing.icon
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var pill

    public init(
        selection: Binding<Value>, items: [AppTabBarItem<Value>], actionTitle: Text, action: @escaping () -> Void
    ) {
        _selection = selection
        self.items = items
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColor.hairline)
                .frame(height: Spacing.borderWidth)
            ViewThatFits(in: .horizontal) {
                row(showsTitles: true)
                row(showsTitles: false)
            }
            .padding(.horizontal, Spacing.lg + Spacing.xs)
            .padding(.top, Spacing.lg)
        }
        .background(AppColor.background)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func row(showsTitles: Bool) -> some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs / 2) {
                ForEach(items) { item in
                    tab(item, showsTitle: showsTitles)
                }
            }
            Spacer(minLength: 0)
            Button(action: action) {
                label(AppIcon.plus, title: actionTitle, showsTitle: showsTitles, bounces: false)
                    .font(AppFont.caption.weight(.medium))
                    .foregroundStyle(AppColor.onInk)
                    .padding(.horizontal, Spacing.lg)
                    .frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
                    .background(AppColor.ink, in: Capsule())
            }
            .buttonStyle(PressButtonStyle())
            .accessibilityLabel(actionTitle)
        }
    }

    private func tab(_ item: AppTabBarItem<Value>, showsTitle: Bool) -> some View {
        let isSelected = item.value == selection
        return Button {
            guard !isSelected else { return }
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) {
                selection = item.value
            }
        } label: {
            label(item.icon, title: item.title, showsTitle: showsTitle, bounces: isSelected && !reduceMotion)
                .font(AppFont.caption.weight(isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? AppColor.textPrimary : AppColor.textSecondary)
                .padding(.horizontal, Spacing.md)
                .frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(AppColor.track)
                            .matchedGeometryEffect(id: showsTitle, in: pill)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(PressButtonStyle())
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func label(_ icon: Image, title: Text, showsTitle: Bool, bounces: Bool) -> some View {
        HStack(spacing: Spacing.iconGap) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .keyframeAnimator(initialValue: 1.0, trigger: bounces) { content, scale in
                    content.scaleEffect(bounces ? scale : 1)
                } keyframes: { _ in
                    CubicKeyframe(0.8, duration: 0.08)
                    SpringKeyframe(1, duration: 0.4, spring: .bouncy)
                }
                .accessibilityHidden(true)
            if showsTitle {
                title
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }
}

private struct PressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.94 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}
