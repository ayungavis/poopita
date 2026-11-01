import DesignSystem
import SwiftUI

struct EntryFieldSectionView<Accessory: View, Content: View>: View {
    let title: Text
    let isOptional: Bool
    let isMissing: Bool
    @ViewBuilder let accessory: Accessory
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
                accessory
            }
            content
            if isMissing {
                Text("entry.pickOne", bundle: .module)
                    .font(AppFont.caption.weight(.medium)).foregroundStyle(AppColor.destructive)
            }
        }
    }
}

extension EntryFieldSectionView where Accessory == EmptyView {
    init(title: Text, isOptional: Bool, isMissing: Bool, @ViewBuilder content: () -> Content) {
        self.init(title: title, isOptional: isOptional, isMissing: isMissing, accessory: { EmptyView() }, content: content)
    }
}
