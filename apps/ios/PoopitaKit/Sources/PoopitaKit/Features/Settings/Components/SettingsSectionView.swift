import DesignSystem
import SwiftUI

struct SettingsSectionView<Content: View>: View {
    private let title: LocalizedStringKey
    private let footnote: LocalizedStringKey?
    private let content: Content

    init(_ title: LocalizedStringKey, footnote: LocalizedStringKey? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footnote = footnote
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title, bundle: .module)
                .font(AppFont.caption.weight(.medium))
                .foregroundStyle(AppColor.textSecondary)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, Spacing.lg)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
            if let footnote {
                Text(footnote, bundle: .module)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }
}

extension View {
    func settingsRow() -> some View {
        font(AppFont.body)
            .foregroundStyle(AppColor.textPrimary)
            .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget + Spacing.xs, alignment: .leading)
    }
}
