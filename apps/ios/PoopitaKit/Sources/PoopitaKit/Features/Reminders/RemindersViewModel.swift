import Foundation
import Observation

@MainActor
@Observable
final class RemindersViewModel {
    private(set) var state: RemindersViewData
    private(set) var errorMessage: String?
    private(set) var route: RemindersRoute?
    private(set) var revision = 0
    private let repository: any ReminderRepository
    private let diary: any DiaryRepository
    private let service: any ReminderService
    private let now: () -> Date
    private let timeZone: () -> TimeZone
    private var preferences: ReminderPreferences
    private var permission = ReminderPermission.notAsked
    private(set) var scheduleTask: Task<Void, Never>?

    init(
        repository: any ReminderRepository, diary: any DiaryRepository, service: any ReminderService,
        now: @escaping () -> Date, timeZone: @escaping () -> TimeZone
    ) {
        self.repository = repository
        self.diary = diary
        self.service = service
        self.now = now
        self.timeZone = timeZone
        let preferences = repository.preferences()
        self.preferences = preferences
        state = Self.viewData(preferences, permission: .notAsked, calendar: Self.calendar(timeZone()))
    }

    func refreshPermission() async {
        permission = await service.permission()
        refresh()
    }

    func requestPermission() async {
        _ = await service.requestPermission()
        await refreshPermission()
        reschedule()
    }

    func setEnabled(_ isOn: Bool) {
        update { $0.isEnabled = isOn }
    }

    func setTime(_ date: Date) {
        let parts = Self.calendar(timeZone()).dateComponents([.hour, .minute], from: date)
        update {
            $0.hour = parts.hour ?? $0.hour
            $0.minute = parts.minute ?? $0.minute
        }
    }

    func toggleDay(_ weekday: Int) {
        guard (1 ... 7).contains(weekday) else { return }
        if preferences.weekdays.contains(weekday) {
            guard preferences.weekdays.count > 1 else { return }
            update { $0.weekdays.remove(weekday) }
        } else {
            update { $0.weekdays.insert(weekday) }
        }
    }

    func setSkipsLoggedDays(_ isOn: Bool) {
        update { $0.skipsLoggedDays = isOn }
    }

    func setSendsWeeklySummary(_ isOn: Bool) {
        update { $0.sendsWeeklySummary = isOn }
    }

    func setAlertsAfterGap(_ isOn: Bool) {
        update { $0.alertsAfterGap = isOn }
    }

    func reschedule() {
        scheduleTask?.cancel()
        guard permission == .allowed else { return }
        let reminders = plan()
        scheduleTask = Task { [service] in
            do {
                try await service.replace(with: reminders)
            } catch {
                Log.report(error, context: Log.Context(operation: "reminders.schedule"))
            }
        }
    }

    func plan() -> [PlannedReminder] {
        let entries = (try? diary.entries()) ?? []
        let checkIns = ((try? diary.checkIns()) ?? []).filter { $0.coverage == .completed }
        let loggedDays = Set(entries.map { DiaryDay(occurrence: $0.occurrence) } + checkIns.map(\.day))
        let lastActivity = (entries.map(\.occurrence.instant) + checkIns.map(\.reportedAt.instant)).max()
        let context = ReminderPlanner.Context(
            loggedDays: loggedDays, lastActivity: lastActivity, snooze: repository.snooze()
        )
        return ReminderPlanner.plan(preferences, context: context, now: now(), calendar: Self.calendar(timeZone()))
    }

    func handle(_ response: ReminderResponse) async {
        switch response {
        case .opened(.weeklySummary):
            route = .insights
        case .opened, .logNow:
            route = .log
        case .snooze:
            snooze()
        }
        await refreshPermission()
        reschedule()
    }

    func consumeRoute() {
        route = nil
    }

    private func snooze() {
        let calendar = Self.calendar(timeZone())
        let today = ReminderPlanner.diaryDay(now(), calendar: calendar)
        let previous = repository.snooze().flatMap { $0.day == today ? $0.count : nil } ?? 0
        guard ReminderPlanner.canSnooze(after: now(), count: previous, calendar: calendar) else { return }
        do {
            try repository.save(ReminderSnooze(day: today, count: previous + 1, until: now().addingTimeInterval(3600)))
        } catch {
            Log.report(error, context: Log.Context(operation: "reminders.snooze"))
        }
    }

    private func update(_ change: (inout ReminderPreferences) -> Void) {
        var next = preferences
        change(&next)
        guard next != preferences else { return }
        do {
            try repository.save(next)
            preferences = next
            errorMessage = nil
            refresh()
            reschedule()
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }

    private func refresh() {
        state = Self.viewData(preferences, permission: permission, calendar: Self.calendar(timeZone()))
    }

    private static func calendar(_ zone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        calendar.locale = .current
        return calendar
    }
}

extension RemindersViewModel {
    static func viewData(
        _ preferences: ReminderPreferences, permission: ReminderPermission, calendar: Calendar
    ) -> RemindersViewData {
        let time = calendar.date(from: DateComponents(hour: preferences.hour, minute: preferences.minute)) ?? .now
        var timeStyle = Date.FormatStyle(locale: calendar.locale ?? .current, timeZone: calendar.timeZone).hour().minute()
        timeStyle.calendar = calendar
        let timeLabel = time.formatted(timeStyle)
        let daysLabel = daysLabel(preferences.weekdays, calendar: calendar)
        let order = (0 ..< 7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
        let shownPermission: RemindersViewData.Permission = switch permission {
        case .notAsked: .notAsked
        case .denied: .denied
        case .allowed: .allowed
        }
        return RemindersViewData(
            isEnabled: preferences.isEnabled, time: time,
            previewLabel: String(localized: "reminders.previewLabel \(timeLabel)", bundle: .module),
            daysLabel: daysLabel,
            days: order.map {
                RemindersDayViewData(
                    id: $0, title: calendar.standaloneWeekdaySymbols[$0 - 1], isOn: preferences.weekdays.contains($0)
                )
            },
            skipsLoggedDays: preferences.skipsLoggedDays, sendsWeeklySummary: preferences.sendsWeeklySummary,
            alertsAfterGap: preferences.alertsAfterGap,
            permission: shownPermission,
            summary: preferences.isEnabled
                ? timeLabel + ", " + daysLabel.lowercased(with: calendar.locale)
                : String(localized: "reminders.off", bundle: .module)
        )
    }

    static func daysLabel(_ weekdays: Set<Int>, calendar: Calendar) -> String {
        switch weekdays {
        case Set(1 ... 7): return String(localized: "reminders.everyDay", bundle: .module)
        case Set(2 ... 6): return String(localized: "reminders.weekdays", bundle: .module)
        case [1, 7]: return String(localized: "reminders.weekends", bundle: .module)
        default:
            let order = (0 ..< 7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
            return order.filter(weekdays.contains).map { calendar.shortStandaloneWeekdaySymbols[$0 - 1] }
                .formatted(.list(type: .and, width: .narrow))
        }
    }
}
