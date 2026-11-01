import Foundation

struct HistoryViewData: Equatable, Sendable {
    let monthLabel: String
    let monthName: String
    let yearLabel: String
    let canMoveNext: Bool
    let calendar: HistoryCalendarViewData
    let logSummary: String
    let unrecorded: HistoryUnrecordedViewData?
    let selected: HistorySelectionViewData
    let isShowingToday: Bool
}

struct HistoryUnrecordedViewData: Equatable, Sendable {
    let dayID: String
    let label: String
}

struct HistorySelectionViewData: Equatable, Sendable {
    enum Content: Equatable, Sendable {
        case entries([TodayEntryViewData], logLabel: String)
        case pastDay(status: String, detail: String, logLabel: String, canConfirm: Bool, mark: DayMarkViewData)
        case open(logLabel: String)
    }

    let dayID: String
    let dateLabel: String
    let countLabel: String?
    let content: Content
}
