import Foundation

struct RemindersViewData: Equatable, Sendable {
    enum Permission: Equatable, Sendable {
        case notAsked, denied, allowed
    }

    let isEnabled: Bool
    let time: Date
    let previewLabel: String
    let daysLabel: String
    let days: [RemindersDayViewData]
    let skipsLoggedDays: Bool
    let sendsWeeklySummary: Bool
    let alertsAfterGap: Bool
    let permission: Permission
    let summary: String
}

struct RemindersDayViewData: Identifiable, Equatable, Sendable {
    let id: Int
    let title: String
    let isOn: Bool
}

enum RemindersRoute: Equatable, Sendable {
    case log, insights
}
