import Foundation

struct TodayWeekDayViewData: Equatable, Sendable, Identifiable {
    enum Mark: Equatable, Sendable {
        case logs(Int), noPoop, noneSoFar, unrecorded, future, open
    }

    let dayID: String
    let dayNumber: String
    let weekdaySymbol: String
    let isToday: Bool
    let isSelected: Bool
    let mark: Mark
    let accessibilityLabel: String
    var id: String {
        dayID
    }
}
