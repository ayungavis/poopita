import Foundation

struct InsightsViewData: Equatable, Sendable {
    let period: InsightsPeriod
    let title: String
    let detail: String?
    let accessibilityLabel: String
    let canMoveNext: Bool
    let headline: String
    let usual: String?
    let comparison: String?
    let unrecorded: HistoryUnrecordedViewData?
    let when: InsightsWhenViewData
    let types: [InsightsTypeViewData]
    let frequency: InsightsFrequencyViewData
}

struct InsightsWhenViewData: Equatable, Sendable {
    let startMinute: Int
    let endMinute: Int
    let hourMarks: [InsightsHourMarkViewData]
    let columns: [InsightsColumnViewData]
}

struct InsightsHourMarkViewData: Equatable, Sendable, Identifiable {
    let minute: Int
    let label: String
    var id: Int {
        minute
    }
}

struct InsightsColumnViewData: Equatable, Sendable, Identifiable {
    let id: String
    let cell: InsightsDayCellViewData?
    let label: String?
    let logMinutes: [Int]
    let checkInMinute: Int?
    let nowMinute: Int?
    let isUnrecorded: Bool
    let isToday: Bool
    let summary: String
}

struct InsightsDayCellViewData: Equatable, Sendable {
    let weekday: String
    let number: String
    let mark: DayMarkViewData
    let isToday: Bool
}

struct InsightsTypeViewData: Equatable, Sendable, Identifiable {
    let id: Int
    let title: String
    let illustration: EntryIllustrationKind?
    let days: String
    let count: String
}

struct InsightsFrequencyViewData: Equatable, Sendable {
    let average: String
    let basis: String
    let bars: [InsightsBarViewData]
    let breakdownTitle: String
    let breakdown: [InsightsBreakdownViewData]
}

struct InsightsBarViewData: Equatable, Sendable, Identifiable {
    let id: String
    let cell: InsightsDayCellViewData?
    let label: String?
    let ratio: Double
    let isUnrecorded: Bool
    let summary: String
}

struct InsightsBreakdownViewData: Equatable, Sendable, Identifiable {
    let id: String
    let mark: DayMarkViewData?
    let title: String
    let count: String
}
