import Foundation

struct PatternsViewData: Equatable, Sendable {
    let range: PatternsRange
    let totalEntries: Int
    let dateRangeLabel: String
    let summaryLabel: String
    let coverage: PatternsCoverageViewData
    let dailyActivity: [PatternsDailyActivityViewData]
    let dayDetails: [PatternsDayDetailViewData]
    let timeOfDay: PatternsTimeOfDaySectionViewData
    let consistency: PatternsConsistencySectionViewData
    let activityBuckets: [PatternsActivityBucketViewData]
    let timeline: [PatternsTimelinePointViewData]
    let amount: PatternsObservationSectionViewData
    let effort: PatternsObservationSectionViewData
}

struct PatternsActivityBucketViewData: Equatable, Sendable, Identifiable {
    let id: String
    let label: String
    let detailLabel: String
    let count: Int
    let dayIDs: [String]
    let coverage: PatternsCoverageViewData
    let isPartial: Bool
}

struct PatternsTimelinePointViewData: Equatable, Sendable, Identifiable {
    let id: UUID
    let hour: Double
    let timeLabel: String
}

struct PatternsObservationSectionViewData: Equatable, Sendable {
    let items: [PatternsObservationItemViewData]
    let recordedCount: Int
    let totalEntries: Int
    let missingCount: Int
}

struct PatternsObservationItemViewData: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let count: Int
    let ratio: Double
    let percentageLabel: String
}

struct PatternsCoverageViewData: Equatable, Sendable {
    let loggedDays: Int
    let confirmedNoPoopDays: Int
    let partialDays: Int
    let unrecordedDays: Int
}

struct PatternsDayDetailViewData: Equatable, Sendable, Identifiable {
    let dayID: String
    let weekdaySymbol: String
    let dayNumber: String
    let dateLabel: String
    let statusLabel: String
    let statusMark: String
    let entryCount: Int
    let entries: [PatternsEntryViewData]
    var id: String {
        dayID
    }
}

struct PatternsEntryViewData: Equatable, Sendable, Identifiable {
    let id: UUID
    let timeLabel: String
    let stoolType: String
    let amount: String?
    let effort: String?
    let note: String?
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
    let totalEntries: Int
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
