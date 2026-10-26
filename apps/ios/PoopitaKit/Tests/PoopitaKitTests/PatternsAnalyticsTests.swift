import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct PatternsAnalyticsTests {
    @Test func timeOfDayAllocatesAcrossFourWindowsUsingOccurrenceLocalHour() throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let today = try date("2026-10-20T12:00:00Z")
        let morning = try entry(day: date("2026-10-20T07:30:00Z"), type: 4)
        let afternoon = try entry(day: date("2026-10-20T14:15:00Z"), type: 4)
        let evening = try entry(day: date("2026-10-20T19:45:00Z"), type: 4)
        let night = try entry(day: date("2026-10-20T23:10:00Z"), type: 4)
        let entries = [morning, afternoon, evening, night]

        let data = try PatternsViewModel.viewData(for: entries, checkIns: [], range: .sevenDays, today: today, timeZone: zone)
        let periods = Dictionary(uniqueKeysWithValues: data.timeOfDay.periods.map { ($0.period, $0.count) })
        #expect(periods[.morning] == 1)
        #expect(periods[.afternoon] == 1)
        #expect(periods[.evening] == 1)
        #expect(periods[.night] == 1)
        #expect(data.timeOfDay.totalEntries == 4)
    }

    @Test func stoolConsistencyTracksClassifiedEntriesAndExplicitDenominator() throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let today = try date("2026-10-20T12:00:00Z")
        let type4A = try entry(day: date("2026-10-20T08:00:00Z"), type: 4)
        let type4B = try entry(day: date("2026-10-20T09:00:00Z"), type: 4)
        let type1 = try entry(day: date("2026-10-20T10:00:00Z"), type: 1)
        let unclassified = try entry(day: date("2026-10-20T11:00:00Z"), type: nil)
        let entries = [type4A, type4B, type1, unclassified]

        let data = try PatternsViewModel.viewData(for: entries, checkIns: [], range: .sevenDays, today: today, timeZone: zone)
        let todayDetail = try #require(data.dayDetails.last)
        #expect(todayDetail.entryCount == 4)
        #expect(todayDetail.entries.count == 4)
        #expect(todayDetail.entries.contains { $0.stoolType == "Type 4" })
        #expect(todayDetail.entries.contains { $0.stoolType == "Stool type not recorded" })
        #expect(data.consistency.totalClassified == 3)
        #expect(data.consistency.totalEntries == 4)
        #expect(data.consistency.ratioLabel == "3 of 4 entries include a type.")
        let type4Item = try #require(data.consistency.items.first(where: { $0.type == 4 }))
        #expect(type4Item.count == 2)
        let type1Item = try #require(data.consistency.items.first(where: { $0.type == 1 }))
        #expect(type1Item.count == 1)
    }

    @Test func consistencyRetainsEveryOrdinalIncludingMissingAndZeroCounts() throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let today = try date("2026-10-20T12:00:00Z")
        let data = try PatternsViewModel.viewData(
            for: [entry(day: today, type: nil)], checkIns: [], range: .oneDay, today: today, timeZone: zone
        )
        #expect(data.consistency.items.map(\.type) == Array(1 ... 7))
        #expect(data.consistency.items.allSatisfy { $0.count == 0 && $0.ratio == 0 })
        #expect(!data.consistency.hasEntries)
        #expect(data.amount.items.map(\.id) == DiaryEntry.Amount.allCases.map(\.rawValue))
        #expect(data.effort.items.map(\.id) == DiaryEntry.Effort.allCases.map(\.rawValue))
        #expect(data.amount.recordedCount == 0 && data.amount.missingCount == 1)
        #expect(data.effort.recordedCount == 0 && data.effort.missingCount == 1)
        #expect(data.amount.items.allSatisfy { $0.count == 0 && $0.ratio == 0 && $0.percentageLabel == "0%" })
    }

    @Test func monthlyBucketsPartitionInclusiveYearAndMarkPartialEdges() throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let today = try date("2026-10-20T12:00:00Z")
        let data = try PatternsViewModel.viewData(
            for: [entry(day: today, type: 4)], checkIns: [], range: .oneYear, today: today, timeZone: zone
        )
        #expect(data.activityBuckets.count == 13)
        #expect(data.activityBuckets.flatMap(\.dayIDs) == data.dailyActivity.map(\.dayID))
        #expect(Set(data.activityBuckets.flatMap(\.dayIDs)).count == 366)
        #expect(data.activityBuckets.first?.dayIDs.count == 12)
        #expect(data.activityBuckets.last?.dayIDs.count == 20)
        #expect(data.activityBuckets.first?.isPartial == true)
        #expect(data.activityBuckets.last?.isPartial == true)
        #expect(data.activityBuckets.dropFirst().dropLast().allSatisfy { !$0.isPartial })
        #expect(data.activityBuckets.map(\.id).first != data.activityBuckets.map(\.id).last)
        #expect(data.activityBuckets.map(\.count).reduce(0, +) == 1)
        #expect(data.dayDetails.first?.dateLabel.contains("2025") == true)
        #expect(data.dayDetails.last?.dateLabel.contains("2026") == true)
    }

    @Test(arguments: ["2024-02-29T12:00:00Z", "2025-02-28T12:00:00Z", "2026-01-01T12:00:00Z"])
    func leapAndCalendarYearEdgesRemainInclusive(_ instant: String) throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let today = try date(instant)
        let data = try PatternsViewModel.viewData(
            for: [], checkIns: [], range: .oneYear, today: today, timeZone: zone
        )
        #expect(data.activityBuckets.count == 13)
        #expect(data.activityBuckets.flatMap(\.dayIDs) == data.dailyActivity.map(\.dayID))
        #expect(data.dailyActivity.count == (instant.hasPrefix("2026") ? 366 : 367))
        #expect(data.dailyActivity.first?.dayID == (instant.hasPrefix("2024") ? "2023-02-28" :
                instant.hasPrefix("2025") ? "2024-02-28" : "2025-01-01"))
        #expect(data.activityBuckets.first?.isPartial == !instant.hasPrefix("2026"))
    }

    @Test func storedLocalTimesSurviveTravelAndRepeatedDSTHour() throws {
        let zone = try #require(TimeZone(identifier: "America/New_York"))
        let viewerZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let first = try OccurrenceTime(instant: date("2025-11-02T05:30:00Z"), timeZone: zone)
        let second = try OccurrenceTime(instant: date("2025-11-02T06:30:00Z"), timeZone: zone)
        let entries = [first, second].map {
            DiaryEntry(id: UUID(), occurrence: $0, stoolType: nil, amount: nil, effort: nil, note: "")
        }
        let data = try PatternsViewModel.viewData(
            for: entries, checkIns: [], range: .sevenDays,
            today: date("2025-11-02T12:00:00Z"), timeZone: viewerZone
        )
        #expect(data.timeline.map(\.hour) == [1.5, 1.5])
        #expect(Set(data.timeline.map(\.id)) == Set(entries.map(\.id)))
        #expect(data.dayDetails.last?.entries.map(\.timeLabel) == data.timeline.map(\.timeLabel))
        #expect(Set(data.timeline.map(\.timeLabel)).count == 1)
        let label = try #require(data.timeline.first?.timeLabel)
        #expect(label.contains("30") && (label.contains("1") || label.contains("01")))
        #expect(data.dailyActivity.last?.count == 2)
        #expect(data.dayDetails.last?.dayID == "2025-11-02")
    }

    @Test(arguments: ["2026-03-08T16:00:00Z", "2026-11-01T17:00:00Z"])
    func daylightSavingRangesContainSevenDistinctLocalDays(_ instant: String) throws {
        let zone = try #require(TimeZone(identifier: "America/New_York"))
        let data = try PatternsViewModel.viewData(
            for: [], checkIns: [], range: .sevenDays, today: date(instant), timeZone: zone
        )
        #expect(data.activityBuckets.count == 7)
        #expect(Set(data.activityBuckets.flatMap(\.dayIDs)).count == 7)
        #expect(data.activityBuckets.allSatisfy { $0.dayIDs.count == 1 && !$0.isPartial })
        #expect(data.activityBuckets.map(\.coverage.unrecordedDays) == Array(repeating: 1, count: 7))
    }

    @Test func observationsUseRecordedDenominatorAndRetainOrdinalZeroes() throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let today = try date("2026-10-20T12:00:00Z")
        let occurrence = try OccurrenceTime(instant: today, timeZone: zone)
        let entries = (0 ..< 4).map { index in
            DiaryEntry(
                id: UUID(), occurrence: occurrence, stoolType: index == 3 ? nil : 4,
                amount: index == 3 ? nil : index == 0 ? .verySmall : .large,
                effort: index == 3 ? nil : index == 0 ? .easy : .difficult, note: ""
            )
        }
        let data = try PatternsViewModel.viewData(
            for: entries, checkIns: [], range: .oneDay, today: today, timeZone: zone
        )
        #expect(data.amount.items.map(\.count) == [1, 0, 0, 2, 0])
        #expect(data.effort.items.map(\.count) == [1, 0, 2])
        for section in [data.amount, data.effort] {
            #expect(section.recordedCount == 3 && section.totalEntries == 4 && section.missingCount == 1)
            #expect(abs(section.items.map(\.ratio).reduce(0, +) - 1) < 0.000001)
            #expect(section.items.first?.percentageLabel == "33%")
            #expect(section.items.first?.ratio == 1.0 / 3)
        }
        #expect(data.activityBuckets.first?.count == 4)
        #expect(data.consistency.items.map(\.count) == [0, 0, 0, 3, 0, 0, 0])
    }

    private func entry(day: Date, type: Int?) throws -> DiaryEntry {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let occurrence = try OccurrenceTime(instant: day, timeZone: zone)
        return DiaryEntry(id: UUID(), occurrence: occurrence, stoolType: type, amount: nil, effort: nil, note: "")
    }

    private func date(_ value: String) throws -> Date {
        guard let date = ISO8601DateFormatter().date(from: value) else { throw AppError.invalidOccurrence }
        return date
    }
}
