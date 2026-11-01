import DesignSystem
import SwiftUI

struct TodayContentView: View {
    let viewModel: TodayViewModel
    let data: TodayViewData
    @State private var headerHeight: CGFloat = 0
    @State private var isHeaderHidden = false
    @State private var position = ScrollPosition()
    @State private var scroll = TodayScrollState()

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        scrollView
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    scroll.restart()
                    centerOnFocus()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    TodayToolbarTitleView(monthLabel: data.monthLabel, title: data.title, isCompact: isHeaderHidden)
                }
                .sharedBackgroundVisibility(.hidden)
            }
            .onChange(of: viewModel.errorMessage) { _, message in
                if let message {
                    AccessibilityNotification.Announcement(message).post()
                }
            }
    }

    private var selectedDayID: String? {
        data.weekDays.first(where: \.isSelected)?.dayID
    }

    private var scrollView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.lg, pinnedViews: .sectionHeaders) {
                TodayHeaderView(data: data)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
                Section {
                    error
                    day
                } header: {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        TodayWeekStripView(weekDays: data.weekDays, selectDay: viewModel.selectDay(id:))
                        summary
                    }
                    .background(AppColor.background)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .scrollPosition($position)
        .onScrollGeometryChange(for: TodayScrollState.Geometry.self) { geometry in
            TodayScrollState.Geometry(
                offset: geometry.contentOffset.y + geometry.contentInsets.top, height: geometry.containerSize.height
            )
        } action: { _, geometry in
            scroll.offset = geometry.offset
            scroll.height = geometry.height
            centerOnFocus()
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > headerHeight
        } action: { _, isHidden in
            isHeaderHidden = isHidden
        }
    }

    private func focusMoved(_ focusY: CGFloat) {
        scroll.focusY = focusY
        centerOnFocus()
    }

    private func centerOnFocus() {
        scroll.prepare(for: selectedDayID)
        if let target = scroll.nextTarget() {
            position.scrollTo(y: target)
        }
    }

    private var summary: some View {
        HStack {
            Text(verbatim: data.sinceLastLog)
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
                timeline: data.timeline, startMinute: 0, edit: viewModel.edit(id:), log: viewModel.presentLogSheet,
                focusMoved: focusMoved
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
                    log: viewModel.presentLogSheet, focusMoved: focusMoved
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
    private var error: some View {
        if let error = viewModel.errorMessage {
            Text(verbatim: error)
                .foregroundStyle(AppColor.destructive)
        }
    }
}
