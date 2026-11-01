import DesignSystem
import SwiftUI

struct SettingsExportRowView: View {
    let item: SettingsExportViewData
    let title: LocalizedStringKey
    let format: String

    var body: some View {
        ShareLink(item: item, preview: SharePreview(Text(title, bundle: .module))) {
            HStack(spacing: Spacing.sm) {
                Text(title, bundle: .module)
                Spacer(minLength: Spacing.md)
                Text(verbatim: format)
                    .foregroundStyle(AppColor.textSecondary)
                Image(systemName: "chevron.right")
                    .font(AppFont.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .accessibilityHidden(true)
            }
            .cardRow()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
