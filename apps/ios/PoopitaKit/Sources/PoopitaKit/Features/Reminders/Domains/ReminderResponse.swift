enum ReminderResponse: Equatable, Sendable {
    case opened(PlannedReminder.Kind)
    case logNow
    case snooze
}
