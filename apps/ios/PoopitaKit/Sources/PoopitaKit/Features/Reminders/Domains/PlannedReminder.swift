import Foundation

struct PlannedReminder: Equatable, Sendable {
    enum Kind: String, Sendable {
        case daily, weeklySummary, gap
    }

    let kind: Kind
    let date: Date
    var allowsSnooze = false

    var identifier: String {
        "poopita.\(kind.rawValue).\(Int(date.timeIntervalSince1970))"
    }
}
