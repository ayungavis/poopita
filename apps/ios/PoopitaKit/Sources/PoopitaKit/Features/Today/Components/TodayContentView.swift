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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        scrollView
            .onChange(of: selectedDayID) {
                updateScroll { _ in }
                let pinnedOffset = headerHeight + Spacing.lg
                if dayKind == "pastDay", scroll.offset > pinnedOffset {
                    position.scrollTo(y: pinnedOffset)
                }
            }
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

    private var dayKind: String {
        switch data.dayState {
        case .logged: "logged"
        case .waiting: "waiting"
        case .pastDay: "pastDay"
        }
    }

    private var scrollView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.lg, pinnedViews: .sectionHeaders) {
                TodayHeaderView(data: data)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
                Section {
                    error
                    ZStack(alignment: .top) {
                        Color.clear.containerRelativeFrame(.vertical)
                        day
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: dayKind)
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
                offset: geometry.contentOffset.y + geometry.contentInsets.top, height: geometry.containerSize.height,
                contentHeight: geometry.contentSize.height
            )
        } action: { _, geometry in
            updateScroll {
                $0.offset = geometry.offset
                $0.height = geometry.height
            }
            centerOnFocus()
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > headerHeight
        } action: { _, isHidden in
            isHeaderHidden = isHidden
        }
    }

    private var reportFocus: (CGFloat) -> Void {
        let dayID = selectedDayID
        return { focusMoved($0, dayID: dayID) }
    }

    private func focusMoved(_ focusY: CGFloat, dayID: String?) {
        guard scroll.dayID == nil || scroll.dayID == dayID else { return }
        var next = scroll
        next.prepare(for: dayID)
        next.focusY = focusY
        if next != scroll {
            scroll = next
        }
        centerOnFocus()
    }

    private func centerOnFocus() {
        var next = scroll
        let target = next.nextTarget()
        if next != scroll {
            scroll = next
        }
        if let target {
            position.scrollTo(y: target)
        }
    }

    private func updateScroll(_ change: (inout TodayScrollState) -> Void) {
        var next = scroll
        next.prepare(for: selectedDayID)
        change(&next)
        if next != scroll {
            scroll = next
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
                            .contentTransition(.opacity)
                        Image(systemName: "chevron.right").accessibilityHidden(true)
                    }
                    .font(AppFont.caption.weight(.semibold))
                    .foregroundStyle(AppColor.accent)
                    .frame(minHeight: Spacing.touchTarget)
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: data.fillIn)
    }

    @ViewBuilder
    private var day: some View {
        switch data.dayState {
        case .logged:
            TodayTimelineView(
                timeline: data.timeline, startMinute: 0, edit: viewModel.edit(id:), log: viewModel.presentLogSheet,
                move: viewModel.move(id:toMinute:), timeLabel: viewModel.timeLabel(minuteOfDay:),
                focusMoved: reportFocus
            )
            .transition(.opacity)
        case let .waiting(headline, detail, partialNote):
            let nowMinute = data.timeline.now?.minute ?? 0
            VStack(spacing: 0) {
                TodayWaitingView(
                    headline: headline, detail: detail, partialNote: partialNote, hours: data.timeline.hours,
                    nowMinute: nowMinute, checkIn: viewModel.recordCheckInToday
                )
                TodayTimelineView(
                    timeline: data.timeline, startMinute: nowMinute, edit: viewModel.edit(id:),
                    log: viewModel.presentLogSheet, focusMoved: reportFocus
                )
            }
            .transition(.opacity)
        case let .pastDay(status, detail, logLabel, canConfirm, mark):
            TodayPastDayView(
                status: status, detail: detail, logLabel: logLabel, canConfirm: canConfirm, mark: mark,
                log: viewModel.presentLogForSelectedDay, confirm: viewModel.confirmNoPoopForSelectedDay
            )
            .transition(.opacity)
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
