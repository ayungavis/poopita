import DesignSystem
import SwiftUI

struct TodayContentView: View {
    let viewModel: TodayViewModel
    let data: TodayViewData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                TodayHeaderView(data: data)
                TodayWeekStripView(weekDays: data.weekDays, selectDay: viewModel.selectDay(id:))
                summary
                feedback
                day
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
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

    private var summary: some View {
        HStack {
            Text(verbatim: data.weekSummary)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
            if let fillIn = data.fillIn {
                Button {
                    viewModel.selectDay(id: fillIn.dayID)
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Text(verbatim: fillIn.label)
                        Image(systemName: "chevron.right").accessibilityHidden(true)
                    }
                    .font(AppFont.caption.weight(.semibold))
                    .foregroundStyle(AppColor.accent)
                    .frame(minHeight: Spacing.touchTarget)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var day: some View {
        switch data.dayState {
        case .logged:
            TodayTimelineView(
                timeline: data.timeline, startMinute: 0, edit: viewModel.edit(id:), log: viewModel.presentLogSheet
            )
        case let .waiting(headline, detail, partialNote):
            let nowMinute = data.timeline.now?.minute ?? 0
            VStack(spacing: 0) {
                TodayWaitingView(
                    headline: headline, detail: detail, partialNote: partialNote, hours: data.timeline.hours,
                    nowMinute: nowMinute, checkIn: viewModel.recordCheckInToday
                )
                TodayTimelineView(
                    timeline: data.timeline, startMinute: nowMinute, edit: viewModel.edit(id:),
                    log: viewModel.presentLogSheet
                )
            }
        case let .pastDay(status, detail, logLabel, canConfirm):
            TodayPastDayView(
                status: status, detail: detail, logLabel: logLabel, canConfirm: canConfirm,
                log: viewModel.presentLogForSelectedDay, confirm: viewModel.confirmNoPoopForSelectedDay
            )
        }
    }

    @ViewBuilder
    private var feedback: some View {
        if let message = viewModel.feedback {
            HStack {
                Text(verbatim: message.message)
                Spacer()
                if data.canUndo {
                    Button(action: viewModel.undo) {
                        Text("diary.undo", bundle: .module)
                            .font(AppFont.body.weight(.semibold))
                    }
                    .frame(minHeight: Spacing.touchTarget)
                }
            }
            .padding(.horizontal, Spacing.md)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
        }
        if let error = viewModel.errorMessage {
            Text(verbatim: error)
                .foregroundStyle(AppColor.destructive)
        }
    }
}
