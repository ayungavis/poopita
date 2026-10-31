import DesignSystem
import SwiftUI

struct EntryFieldSectionView<Content: View>: View {
    let title: Text
    let isOptional: Bool
    let isMissing: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                title
                    .font(AppFont.caption.weight(.medium))
                    .foregroundStyle(isMissing ? AppColor.destructive : AppColor.textSecondary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if isOptional {
                    Text("entry.optional", bundle: .module)
                        .font(AppFont.caption).foregroundStyle(AppColor.textSecondary)
                }
            }
            content
            if isMissing {
                Text("entry.pickOne", bundle: .module)
                    .font(AppFont.caption.weight(.medium)).foregroundStyle(AppColor.destructive)
            }
        }
    }
}
