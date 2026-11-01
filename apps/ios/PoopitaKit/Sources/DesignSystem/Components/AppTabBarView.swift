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
                label(AppIcon.plus, title: actionTitle, showsTitle: showsTitles)
                    .font(AppFont.caption.weight(.medium))
                    .foregroundStyle(AppColor.onInk)
                    .padding(.horizontal, Spacing.lg)
                    .frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
                    .background(AppColor.ink, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(actionTitle)
        }
    }

    private func tab(_ item: AppTabBarItem<Value>, showsTitle: Bool) -> some View {
        let isSelected = item.value == selection
        return Button {
            selection = item.value
        } label: {
            label(item.icon, title: item.title, showsTitle: showsTitle)
                .font(AppFont.caption.weight(isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? AppColor.textPrimary : AppColor.textSecondary)
                .padding(.horizontal, Spacing.md)
                .frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
                .background(isSelected ? AppColor.track : .clear, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func label(_ icon: Image, title: Text, showsTitle: Bool) -> some View {
        HStack(spacing: Spacing.iconGap) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)
            if showsTitle {
                title
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }
}
