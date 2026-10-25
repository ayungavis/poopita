import DesignSystem
import SwiftUI

struct HistoryEntryRowView: View {
    let entry: TodayEntryViewData
    let edit: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Button(action: edit) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    Image(systemName: "checkmark.circle").foregroundStyle(AppColor.accent).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(verbatim: entry.timeLabel).font(AppFont.body.weight(.semibold))
                        Text(verbatim: entry.observations).font(AppFont.caption).foregroundStyle(AppColor.textSecondary)
                        if !entry.note.isEmpty {
                            Text(verbatim: entry.note).font(AppFont.body)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundStyle(AppColor.textPrimary)
                .padding(Spacing.lg)
                .frame(minHeight: Spacing.touchTarget, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint(Text("entry.editHint", bundle: .module))
            Button(role: .destructive, action: delete) {
                Image(systemName: "trash")
                    .frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
            }
            .accessibilityLabel(Text("entry.delete", bundle: .module))
        }
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }
}
