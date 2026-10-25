import Foundation

struct HistoryCalendarViewData: Equatable, Sendable {
    let weekdays: [String]
    let days: [HistoryDayViewData?]
}
