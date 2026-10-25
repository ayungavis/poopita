import Foundation

struct PatternsViewData: Equatable, Sendable {
    let range: PatternsRange
    let totalEntries: Int
    let dateRangeLabel: String
    let summaryLabel: String
    let dailyActivity: [PatternsDailyActivityViewData]
    let timeOfDay: PatternsTimeOfDaySectionViewData
    let consistency: PatternsConsistencySectionViewData
}

struct PatternsDailyActivityViewData: Equatable, Sendable, Identifiable {
    let dayID: String
    let label: String
    let count: Int
    let ratio: Double
    let status: PatternsDayStatus
    let statusMark: String
    let accessibilityLabel: String
    var id: String {
        dayID
    }
}

enum PatternsDayStatus: Equatable, Sendable {
    case logged
    case confirmedNoPoop
    case partialCheckIn
    case unrecorded
}

struct PatternsTimeOfDaySectionViewData: Equatable, Sendable {
    let periods: [PatternsPeriodViewData]
    let hasEntries: Bool
}

struct PatternsPeriodViewData: Equatable, Sendable, Identifiable {
    let period: PatternsTimePeriod
    let title: String
    let count: Int
    let ratio: Double
    var id: PatternsTimePeriod {
        period
    }
}

enum PatternsTimePeriod: Equatable, Sendable {
    case morning
    case afternoon
    case evening
    case night
}

struct PatternsConsistencySectionViewData: Equatable, Sendable {
    let items: [PatternsConsistencyItemViewData]
    let totalClassified: Int
    let totalEntries: Int
    let hasEntries: Bool
    let ratioLabel: String
}

struct PatternsConsistencyItemViewData: Equatable, Sendable, Identifiable {
    let type: Int
    let title: String
    let count: Int
    let ratio: Double
    var id: Int {
        type
    }
}
