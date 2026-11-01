import Foundation

enum ReminderPlanner {
    static let horizonDays = 14
    static let gapDays = 3
    static let summaryHour = 19

    static func plan(
        _ preferences: ReminderPreferences, loggedDays: Set<DiaryDay>, lastActivity: Date?, now: Date, calendar: Calendar
    ) -> [PlannedReminder] {
        guard let today = calendar.dateInterval(of: .day, for: now)?.start else { return [] }
        var reminders: [PlannedReminder] = []
        for offset in 0 ..< horizonDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            let skipped = preferences.skipsLoggedDays && loggedDays.contains(diaryDay(day, calendar: calendar))
            let daily = time(preferences.hour, preferences.minute, on: day, after: now, calendar: calendar)
            if preferences.isEnabled, preferences.weekdays.contains(weekday), !skipped, let daily {
                reminders.append(PlannedReminder(kind: .daily, date: daily))
            }
            let summary = time(summaryHour, 0, on: day, after: now, calendar: calendar)
            if preferences.sendsWeeklySummary, weekday == 1, let summary {
                reminders.append(PlannedReminder(kind: .weeklySummary, date: summary))
            }
        }
        let lastDay = calendar.dateInterval(of: .day, for: lastActivity ?? now)?.start ?? today
        let alertDay = calendar.date(byAdding: .day, value: gapDays, to: lastDay) ?? today
        let gap = time(preferences.hour, preferences.minute, on: alertDay, after: now, calendar: calendar)
        if preferences.alertsAfterGap, let gap {
            reminders.append(PlannedReminder(kind: .gap, date: gap))
        }
        return reminders.sorted { $0.date < $1.date }
    }

    private static func time(_ hour: Int, _ minute: Int, on day: Date, after now: Date, calendar: Calendar) -> Date? {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day).flatMap { $0 > now ? $0 : nil }
    }

    private static func diaryDay(_ date: Date, calendar: Calendar) -> DiaryDay {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return DiaryDay(year: parts.year ?? 0, month: parts.month ?? 0, day: parts.day ?? 0)
    }
}
