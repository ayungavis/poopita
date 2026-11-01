import Foundation

struct HistoryViewData: Equatable, Sendable {
    let monthLabel: String
    let canMoveNext: Bool
    let calendar: HistoryCalendarViewData
    let selected: HistorySelectionViewData
    let todayID: String
}

struct HistorySelectionViewData: Equatable, Sendable {
    let dayID: String
    let dateLabel: String
    let status: HistoryDayViewData.Status
    let entries: [TodayEntryViewData]
    let checkInStatus: String?
    let canConfirmNoPoop: Bool
}
