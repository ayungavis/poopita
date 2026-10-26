import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct PatternsFlowTests {
    @Test func fourRangesFilterEntriesUsingCalendarBoundaries() throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let today = try date("2026-10-20T12:00:00Z")
        let todayEntry = try entry(day: date("2026-10-20T08:00:00Z"), type: 4)
        let sixDaysAgo = try entry(day: date("2026-10-14T14:00:00Z"), type: 3)
        let sevenDaysAgo = try entry(day: date("2026-10-13T12:00:00Z"), type: 1)
        let twentySevenDaysAgo = try entry(day: date("2026-09-23T12:00:00Z"), type: 2)
        let twentyEightDaysAgo = try entry(day: date("2026-09-22T12:00:00Z"), type: 6)
        let yearAgo = try entry(day: date("2025-10-20T12:00:00Z"), type: 1)
        let entries = [todayEntry, sixDaysAgo, sevenDaysAgo, twentySevenDaysAgo, twentyEightDaysAgo, yearAgo]

        let oneDay = try PatternsViewModel.viewData(for: entries, checkIns: [], range: .oneDay, today: today, timeZone: zone)
        #expect(oneDay.totalEntries == 1)
        #expect(oneDay.dailyActivity.count == 1)
        #expect(oneDay.coverage.loggedDays == 1)

        let sevenDays = try PatternsViewModel.viewData(
            for: entries, checkIns: [], range: .sevenDays, today: today, timeZone: zone
        )
        #expect(sevenDays.totalEntries == 2)
        #expect(sevenDays.dailyActivity.count == 7)
        #expect(sevenDays.coverage.loggedDays == 2)
        #expect(sevenDays.coverage.unrecordedDays == 5)

        let fourWeeks = try PatternsViewModel.viewData(
            for: entries, checkIns: [], range: .fourWeeks, today: today, timeZone: zone
        )
        #expect(fourWeeks.totalEntries == 4)
        #expect(fourWeeks.dailyActivity.count == 28)
        #expect(fourWeeks.coverage.loggedDays == 4)

        let oneYear = try PatternsViewModel.viewData(for: entries, checkIns: [], range: .oneYear, today: today, timeZone: zone)
        #expect(oneYear.totalEntries == 6)
        #expect(oneYear.dailyActivity.count == 366)
        #expect(oneYear.dateRangeLabel == "Oct 2025 – Oct 2026")
        #expect(oneYear.coverage.loggedDays == 6)
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
            for: entries, checkIns: checkIns, range: .sevenDays, today: today, timeZone: zone
        )
        let activity = data.dailyActivity
        #expect(data.dayDetails.count == 7)
        #expect(data.dayDetails.last?.statusLabel == "Bowel movements recorded")
        #expect(data.dayDetails[data.dayDetails.count - 2].statusLabel == "No poop that day")
        #expect(data.dayDetails[data.dayDetails.count - 3].statusLabel == "None so far today")
        #expect(data.dayDetails[data.dayDetails.count - 4].statusLabel == "Not recorded")
        #expect(data.coverage.loggedDays == 1)
        #expect(data.coverage.confirmedNoPoopDays == 1)
        #expect(data.coverage.partialDays == 1)
        #expect(data.coverage.unrecordedDays == 4)
        #expect(data.coverage.loggedDays + data.coverage.confirmedNoPoopDays + data.coverage.partialDays + data.coverage
            .unrecordedDays == data.dailyActivity.count)
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

    @Test func viewModelRangeSelectionUpdatesState() async throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let clock = try date("2026-10-20T12:00:00Z")
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: fixture()))
        let model = PatternsViewModel(repository: repository, now: { clock }, timeZone: { zone })
        model.load()
        await model.loadTask?.value
        #expect(model.selectedRange == .sevenDays)
        #expect(Self.loaded(model.state)?.range == .sevenDays)

        model.selectRange(.oneYear)
        await model.loadTask?.value
        #expect(model.selectedRange == .oneYear)
        #expect(Self.loaded(model.state)?.range == .oneYear)
    }

    @Test func rangeSwitchImmediatelyHidesStaleDataAndLatestLoadWins() async throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let clock = try date("2026-10-20T12:00:00Z")
        let repository = PatternsTestRepository()
        let model = PatternsViewModel(repository: repository, now: { clock }, timeZone: { zone })
        model.load()
        await model.loadTask?.value
        model.selectRange(.oneYear)
        #expect(Self.loaded(model.state) == nil)
        model.selectRange(.oneDay)
        await model.loadTask?.value
        #expect(Self.loaded(model.state)?.range == .oneDay)
        #expect(repository.entryReads == 2)
    }

    @Test func loadFailuresCancellationAndRetryAreRecoverable() async throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let clock = try date("2026-10-20T12:00:00Z")
        let repository = PatternsTestRepository()
        let model = PatternsViewModel(repository: repository, now: { clock }, timeZone: { zone })
        model.load()
        model.loadTask?.cancel()
        await model.loadTask?.value
        #expect(model.state == .idle)
        #expect(repository.entryReads == 0)
        repository.error = .storageRead
        model.load()
        await model.loadTask?.value
        #expect(model.state == .failed(.storageRead))
        repository.error = nil
        model.load()
        await model.loadTask?.value
        let loaded = model.state
        model.load()
        model.loadTask?.cancel()
        await model.loadTask?.value
        #expect(model.state == loaded)
        #expect(Self.loaded(model.state)?.range == .sevenDays)
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

@MainActor
private final class PatternsTestRepository: DiaryRepository {
    let canUndo = false
    var error: AppError?
    var entryReads = 0

    func entries() throws -> [DiaryEntry] {
        entryReads += 1
        if let error {
            throw error
        }
        return []
    }

    func checkIns() throws -> [NoPoopCheckIn] {
        []
    }

    func saveCheckIn(_: NoPoopCheckIn) throws {}
    func save(_: DiaryEntry) throws -> DiaryEntrySaveResult {
        .saved
    }

    func delete(id _: UUID) throws {}
    func deleteAll() throws {}
    func undo() throws {}
}
