import DesignSystem
import SwiftUI

struct RecoveryKeyGridView: View {
    let groups: [String]
    let shareText: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 4), spacing: Spacing.sm) {
                ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                    Text(verbatim: group)
                        .font(AppFont.body.weight(.semibold))
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
                        .background(AppColor.background, in: RoundedRectangle(cornerRadius: Spacing.sm))
                }
            }
            .textSelection(.enabled)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("backup.key.title", bundle: .module))
            .accessibilityValue(Text(verbatim: groups.map { $0.map(String.init).joined(separator: " ") }.joined(separator: ", ")))
            ShareLink(item: shareText) {
                Label {
                    Text("backup.key.share", bundle: .module)
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                }
                .font(AppFont.body.weight(.semibold))
                .foregroundStyle(AppColor.accent)
                .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
        .privacySensitive()
    }
}
