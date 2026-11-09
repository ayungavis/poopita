enum ReminderCategory {
    static let daily = "poopita.daily"
    static let dailyLastCall = "poopita.daily.lastCall"
    static let weeklySummary = "poopita.weeklySummary"
    static let gap = "poopita.gap"
    static let logNow = "poopita.logNow"
    static let snooze = "poopita.snooze"
    static let defaultAction = "com.apple.UNNotificationDefaultActionIdentifier"

    static func identifier(for reminder: PlannedReminder) -> String {
        switch reminder.kind {
        case .daily: reminder.allowsSnooze ? daily : dailyLastCall
        case .weeklySummary: weeklySummary
        case .gap: gap
        }
    }

    static func response(action: String, category: String) -> ReminderResponse? {
        switch (action, category) {
        case (logNow, _): .logNow
        case (snooze, _): .snooze
        case (defaultAction, daily), (defaultAction, dailyLastCall): .opened(.daily)
        case (defaultAction, weeklySummary): .opened(.weeklySummary)
        case (defaultAction, gap): .opened(.gap)
        default: nil
        }
    }
}
