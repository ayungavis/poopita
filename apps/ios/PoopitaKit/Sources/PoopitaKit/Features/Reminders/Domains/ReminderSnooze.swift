import Foundation

struct ReminderSnooze: Codable, Equatable, Sendable {
    static let maximumPerDay = 2
    static let latestHour = 23

    let day: DiaryDay
    let count: Int
    let until: Date?
}
