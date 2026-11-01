import Foundation

struct TodayViewData: Equatable, Sendable {
    let monthLabel: String
    let title: String
    let weekDays: [TodayWeekDayViewData]
    let sinceLastLog: String
    let fillIn: TodayFillInViewData?
    let dayState: TodayDayStateViewData
    let timeline: TodayTimelineViewData
}

struct TodayFillInViewData: Equatable, Sendable {
    let dayID: String
    let label: String
}
