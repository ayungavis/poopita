import DesignSystem
import SwiftUI

struct TodayEntryRowView: View {
    let entry: TodayEntryViewData
    let edit: () -> Void

    var body: some View {
        Button(action: edit) {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: "checkmark.circle").foregroundStyle(AppColor.accent).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(verbatim: entry.dateLabel).font(AppFont.caption).foregroundStyle(AppColor.textSecondary)
                    Text(verbatim: entry.timeLabel).font(AppFont.body.weight(.semibold))
                    Text(verbatim: entry.observations).font(AppFont.caption).foregroundStyle(AppColor.textSecondary)
                    if !entry.note.isEmpty {
                        Text(verbatim: entry.note).font(AppFont.body)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "pencil").accessibilityHidden(true)
            }
            .foregroundStyle(AppColor.textPrimary)
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget, alignment: .leading)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("entry.editHint", bundle: .module))
    }
}
