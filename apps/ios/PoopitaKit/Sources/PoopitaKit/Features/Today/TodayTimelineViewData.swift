import Foundation

struct TodayTimelineViewData: Equatable, Sendable {
    let hours: [TodayTimelineHourViewData]
    let blocks: [TodayTimelineBlockViewData]
    let now: TodayTimelineMarkViewData?
    let sinceLast: TodayTimelineMarkViewData?
    let endMinute: Int
    let latestMinute: Int
}

struct TodayTimelineHourViewData: Equatable, Sendable, Identifiable {
    let minute: Int
    let label: String
    var id: Int {
        minute
    }
}

struct TodayTimelineBlockViewData: Equatable, Sendable, Identifiable {
    let minute: Int
    let entry: TodayEntryViewData
    var id: UUID {
        entry.id
    }
}

struct TodayTimelineMarkViewData: Equatable, Sendable {
    let minute: Int
    let label: String
}
