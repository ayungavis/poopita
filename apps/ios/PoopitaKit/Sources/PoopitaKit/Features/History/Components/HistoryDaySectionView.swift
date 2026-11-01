import DesignSystem
import SwiftUI

struct HistoryDaySectionView: View {
    let data: HistorySelectionViewData
    let edit: (UUID) -> Void
    let log: () -> Void
    let confirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: data.dateLabel)
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Spacing.sm)
                if let countLabel = data.countLabel {
                    Text(verbatim: countLabel)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch data.content {
        case let .entries(entries, logLabel):
            CardSectionView(nil) {
                ForEach(entries) { entry in
                    if entry.id != entries.first?.id {
                        CardDividerView()
                    }
                    HistoryEntryRowView(entry: entry) { edit(entry.id) }
                }
            }
            logLink(logLabel)
        case let .pastDay(status, detail, logLabel, canConfirm, mark):
            PastDayCardView(
                status: status, detail: detail, logLabel: logLabel, canConfirm: canConfirm, mark: mark,
                log: log, confirm: confirm
            )
        case let .open(logLabel):
            logLink(logLabel)
        }
    }

    private func logLink(_ label: String) -> some View {
        Button(action: log) {
            Label {
                Text(verbatim: label)
            } icon: {
                Image(systemName: "plus")
            }
            .font(AppFont.body.weight(.medium))
            .foregroundStyle(AppColor.accent)
            .frame(minHeight: Spacing.touchTarget)
        }
        .buttonStyle(.plain)
    }
}
