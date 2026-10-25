import Foundation

struct TodayViewData: Equatable, Sendable {
    let dateLabel: String
    let weekDays: [TodayWeekDayViewData]
    let heroStatus: TodayHeroStatusViewData
    let canCheckInToday: Bool
    let entries: [TodayEntryViewData]
    let canUndo: Bool
}
