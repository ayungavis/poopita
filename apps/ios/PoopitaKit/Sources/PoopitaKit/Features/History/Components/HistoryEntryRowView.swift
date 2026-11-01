import DesignSystem
import SwiftUI

struct HistoryEntryRowView: View {
    let entry: TodayEntryViewData
    let edit: () -> Void

    var body: some View {
        Button(action: edit) {
            HStack(spacing: Spacing.md) {
                Group {
                    if let illustration = entry.illustration {
                        EntryIllustrationView(kind: illustration)
                    } else {
                        Color.clear
                    }
                }
                .frame(width: Spacing.illustrationWidth)
                .foregroundStyle(AppColor.textPrimary)
                VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                    Text(verbatim: entry.title)
                    if !entry.details.isEmpty {
                        Text(verbatim: entry.details)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: Spacing.sm)
                Text(verbatim: entry.timeLabel)
                    .foregroundStyle(AppColor.textSecondary)
                Image(systemName: "chevron.right")
                    .font(AppFont.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Spacing.md)
            .cardRow()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("entry.editHint", bundle: .module))
    }
}
