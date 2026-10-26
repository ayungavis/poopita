import DesignSystem
import SwiftUI

struct PatternsDayEntryRowView: View {
    let entry: PatternsEntryViewData

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(verbatim: entry.timeLabel).font(AppFont.body.weight(.semibold))
            Text(verbatim: entry.stoolType).font(AppFont.body)
            if let amount = entry.amount {
                LabeledContent { Text(verbatim: amount) } label: { Text("entry.amountLabel", bundle: .module) }
            }
            if let effort = entry.effort {
                LabeledContent { Text(verbatim: effort) } label: { Text("entry.effortLabel", bundle: .module) }
            }
            if let note = entry.note {
                Text(verbatim: note).font(AppFont.body)
            }
        }
        .font(AppFont.caption)
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.background, in: RoundedRectangle(cornerRadius: Spacing.md))
    }
}
