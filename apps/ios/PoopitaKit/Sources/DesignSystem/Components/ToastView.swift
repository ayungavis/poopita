import SwiftUI

public struct ToastView: View {
    private let message: String
    private let actionTitle: Text?
    private let staysUntilDismissed: Bool
    private let action: () -> Void
    private let dismiss: () -> Void
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverOn
    @GestureState private var isPressed = false

    public init(
        message: String, actionTitle: Text?, staysUntilDismissed: Bool,
        action: @escaping () -> Void, dismiss: @escaping () -> Void
    ) {
        self.message = message
        self.actionTitle = actionTitle
        self.staysUntilDismissed = staysUntilDismissed
        self.action = action
        self.dismiss = dismiss
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            Text(verbatim: message)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let actionTitle {
                Button(action: action) {
                    actionTitle
                        .font(AppFont.body.weight(.semibold))
                        .foregroundStyle(AppColor.accent)
                        .padding(.horizontal, Spacing.sm)
                        .frame(minHeight: Spacing.touchTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, Spacing.lg)
        .padding(.trailing, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .glassEffect(.regular.interactive(), in: Capsule())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, pressed, _ in pressed = true }
                .onEnded { value in
                    if value.translation.height > Spacing.lg {
                        dismiss()
                    }
                }
        )
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape, dismiss)
        .task(id: isPressed) {
            guard !isPressed, !staysUntilDismissed, !isVoiceOverOn else { return }
            try? await Task.sleep(for: .seconds(8))
            if !Task.isCancelled {
                dismiss()
            }
        }
        .onAppear {
            AccessibilityNotification.Announcement(message).post()
        }
    }
}
