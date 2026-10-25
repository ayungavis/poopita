import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct PatternsFlowTests {
    @Test func sevenDayAndThirtyDayRangesFilterEntriesCorrectly() throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let today = try date("2026-10-20T12:00:00Z")
        let inSevenDays = try entry(day: date("2026-10-18T10:00:00Z"), type: 4)
        let inThirtyDays = try entry(day: date("2026-10-02T14:00:00Z"), type: 3)
        let older = try entry(day: date("2026-09-10T12:00:00Z"), type: 1)
        let entries = [inSevenDays, inThirtyDays, older]

        let sevenData = try PatternsViewModel.viewData(
            for: entries,
            checkIns: [],
            range: .sevenDays,
            today: today,
            timeZone: zone
        )
        #expect(sevenData.totalEntries == 1)
        #expect(sevenData.dailyActivity.count == 7)

        let thirtyData = try PatternsViewModel.viewData(
            for: entries,
            checkIns: [],
            range: .thirtyDays,
            today: today,
            timeZone: zone
        )
        #expect(thirtyData.totalEntries == 2)
        #expect(thirtyData.dailyActivity.count == 30)
    }

    @Test func dailyActivityDistinguishesAllFourStatesWithoutGuessingMissingData() throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let today = try date("2026-10-20T12:00:00Z")
        let loggedDate = try date("2026-10-20T08:00:00Z")
        let confirmedDate = try date("2026-10-19T00:00:00Z")
        let partialDate = try date("2026-10-18T00:00:00Z")
        let entries = try [entry(day: loggedDate, type: 2), entry(day: loggedDate, type: 3)]
        let checkIns = try [
            NoPoopCheckIn(
                day: DiaryDay(date: confirmedDate, timeZone: zone),
                reportedAt: occurrence(confirmedDate, zone),
                coverage: .completed
            ),
            NoPoopCheckIn(
                day: DiaryDay(date: partialDate, timeZone: zone),
                reportedAt: occurrence(partialDate, zone),
                coverage: .partial
            ),
        ]

        let data = try PatternsViewModel.viewData(
            for: entries,
            checkIns: checkIns,
            range: .sevenDays,
            today: today,
            timeZone: zone
        )
        let activity = data.dailyActivity
        let todayBar = try #require(activity.last)
        #expect(todayBar.count == 2)
        #expect(todayBar.status == .logged)

        let yesterdayBar = activity[activity.count - 2]
        #expect(yesterdayBar.count == 0)
        #expect(yesterdayBar.status == .confirmedNoPoop)

        let twoDaysAgoBar = activity[activity.count - 3]
        #expect(twoDaysAgoBar.count == 0)
        #expect(twoDaysAgoBar.status == .partialCheckIn)

        let threeDaysAgoBar = activity[activity.count - 4]
        #expect(threeDaysAgoBar.count == 0)
        #expect(threeDaysAgoBar.status == .unrecorded)
    }

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
        #expect(data.consistency.totalClassified == 3)
        #expect(data.consistency.totalEntries == 4)
        let type4Item = try #require(data.consistency.items.first(where: { $0.type == 4 }))
        #expect(type4Item.count == 2)
        let type1Item = try #require(data.consistency.items.first(where: { $0.type == 1 }))
        #expect(type1Item.count == 1)
    }

    @Test func viewModelRangeSelectionUpdatesState() async throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let clock = try date("2026-10-20T12:00:00Z")
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: fixture()))
        let model = PatternsViewModel(repository: repository, now: { clock }, timeZone: { zone })
        model.load()
        await model.loadTask?.value
        #expect(model.selectedRange == .sevenDays)
        #expect(Self.loaded(model.state)?.range == .sevenDays)

        model.selectRange(.thirtyDays)
        await model.loadTask?.value
        #expect(model.selectedRange == .thirtyDays)
        #expect(Self.loaded(model.state)?.range == .thirtyDays)
    }

    private static func loaded(_ state: Loadable<PatternsViewData>) -> PatternsViewData? {
        guard case let .loaded(data) = state else { return nil }
        return data
    }

    private func entry(day: Date, type: Int?) throws -> DiaryEntry {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let occurrence = try OccurrenceTime(instant: day, timeZone: zone)
        return DiaryEntry(id: UUID(), occurrence: occurrence, stoolType: type, amount: nil, effort: nil, note: "")
    }

    private func occurrence(_ date: Date, _ zone: TimeZone) throws -> OccurrenceTime {
        try OccurrenceTime(instant: date, timeZone: zone)
    }

    private func date(_ value: String) throws -> Date {
        guard let date = ISO8601DateFormatter().date(from: value) else { throw AppError.invalidOccurrence }
        return date
    }

    private func fixture() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    }
}
