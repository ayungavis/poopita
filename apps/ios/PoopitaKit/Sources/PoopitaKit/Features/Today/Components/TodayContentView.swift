import DesignSystem
import SwiftUI

struct TodayContentView: View {
    let viewModel: TodayViewModel
    let data: TodayViewData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                TodayWeekStripView(
                    weekDays: data.weekDays,
                    selectDay: viewModel.selectDay(id:)
                )

                TodayRoutineRingView(
                    heroStatus: data.heroStatus,
                    canCheckIn: data.canCheckInToday,
                    onLog: viewModel.presentLogSheet,
                    onCheckIn: viewModel.recordCheckInToday
                )

                feedback

                Label {
                    Text("diary.localOnly", bundle: .module)
                } icon: {
                    Image(systemName: "iphone.gen3")
                }
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)

                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("diary.entries", bundle: .module)
                        .font(AppFont.title)
                        .accessibilityAddTraits(.isHeader)

                    if data.entries.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("diary.emptyTitle", bundle: .module)
                                .font(AppFont.body.weight(.semibold))
                            Text("diary.emptyDetail", bundle: .module)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .padding(Spacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
                    } else {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(data.entries) { entry in
                                TodayEntryRowView(entry: entry) {
                                    viewModel.edit(id: entry.id)
                                }
                            }
                        }
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: viewModel.feedback) { _, message in
            if let message {
                AccessibilityNotification.Announcement(message.message).post()
            }
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                AccessibilityNotification.Announcement(message).post()
            }
        }
    }

    @ViewBuilder
    private var feedback: some View {
        if let message = viewModel.feedback {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(verbatim: message.message)
                if data.canUndo {
                    Button(action: viewModel.undo) {
                        Text("diary.undo", bundle: .module)
                    }
                    .frame(minHeight: Spacing.touchTarget)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
        }
        if let error = viewModel.errorMessage {
            Text(verbatim: error)
                .foregroundStyle(AppColor.destructive)
        }
    }
}
