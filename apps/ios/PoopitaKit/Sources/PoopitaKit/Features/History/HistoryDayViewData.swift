import Foundation

struct HistoryDayViewData: Equatable, Sendable, Identifiable {
    let dayID: String
    let number: String
    let accessibilityLabel: String
    let mark: DayMarkViewData
    let isToday: Bool
    let isSelected: Bool
    var id: String {
        dayID
    }
}
