import Foundation

struct ReminderPreferences: Codable, Equatable, Sendable {
    var isEnabled = false
    var hour = 20
    var minute = 0
    var weekdays: Set<Int> = Set(1 ... 7)
    var skipsLoggedDays = true
    var sendsWeeklySummary = true
    var alertsAfterGap = false
}
