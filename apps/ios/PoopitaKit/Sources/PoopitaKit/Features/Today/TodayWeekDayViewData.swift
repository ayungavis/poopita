import Foundation

struct TodayWeekDayViewData: Equatable, Sendable, Identifiable {
    let dayID: String
    let dayNumber: String
    let weekdaySymbol: String
    let isToday: Bool
    let isSelected: Bool
    let hasEntries: Bool
    let isConfirmedNoPoop: Bool
    let isPartialCheckIn: Bool
    let accessibilityLabel: String
    var id: String {
        dayID
    }
}
