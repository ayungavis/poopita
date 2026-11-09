import Foundation

struct InsightsViewData: Equatable, Sendable {
    let period: InsightsPeriod
    let title: String
    let detail: String?
    let accessibilityLabel: String
    let canMoveNext: Bool
    let headline: String
    let headlineDetail: String?
    let summaryNote: String?
    let unrecorded: HistoryUnrecordedViewData?
    let doctor: [InsightsFlagViewData]
    let changes: [InsightsFlagViewData]
    let usual: InsightsUsualViewData
    let consistency: InsightsConsistencyViewData
    let when: InsightsWhenViewData
    let comfort: [InsightsComfortRowViewData]
    let types: [InsightsTypeViewData]
    let frequency: InsightsFrequencyViewData
}

struct InsightsFlagViewData: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let detail: String
    let dayID: String?
}

struct InsightsUsualViewData: Equatable, Sendable {
    let rows: [InsightsUsualRowViewData]
    let note: String
}

struct InsightsUsualRowViewData: Equatable, Sendable, Identifiable {
    let id: String
    let label: String
    let value: String
    let lower: Double
    let upper: Double
    let current: Double
}

struct InsightsConsistencyViewData: Equatable, Sendable {
    let lead: String?
    let rows: [InsightsShareRowViewData]
}

struct InsightsShareRowViewData: Equatable, Sendable, Identifiable {
    let id: String
    let label: String
    let hard: Double
    let usual: Double
    let loose: Double
    let isCurrent: Bool
    let isDimmed: Bool
    let accessibilityLabel: String
}

struct InsightsComfortRowViewData: Equatable, Sendable, Identifiable {
    let id: String
    let label: String
    let value: String
}

struct InsightsWhenViewData: Equatable, Sendable {
    let startMinute: Int
    let endMinute: Int
    let hourMarks: [InsightsHourMarkViewData]
    let columns: [InsightsColumnViewData]
    let isAggregated: Bool
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
    let nowMinute: Int?
    let isUnrecorded: Bool
    let isConfirmedNone: Bool
    let unknownCount: Int?
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
