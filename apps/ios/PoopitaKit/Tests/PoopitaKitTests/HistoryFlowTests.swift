import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct HistoryFlowTests {
    @Test(arguments: [
        ("en", ["M", "T", "W", "T", "F", "S", "S"]),
        ("id", ["S", "S", "R", "K", "J", "S", "M"]),
    ])
    func weekdayHeaderFollowsTheAppLanguageFromMonday(language: String, expected: [String]) {
        let calendar = TodayViewModel.calendar(.gmt)
        #expect(HistoryViewModel.weekdays(calendar, locale: Locale(identifier: language)) == expected)
    }

    @Test func monthCalendarSeparatesAllDayStatesAndKeepsMultipleEntries() throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let today = try date("2026-10-20T12:00:00Z")
        let loggedDay = try DiaryDay(date: date("2026-10-03T00:00:00Z"), timeZone: zone)
        let completedDay = try DiaryDay(date: date("2026-10-04T00:00:00Z"), timeZone: zone)
        let partialDay = try DiaryDay(date: date("2026-10-05T00:00:00Z"), timeZone: zone)
        let entries = try [entry(day: loggedDay, hour: 8), entry(day: loggedDay, hour: 19)]
        let checkIns = try [
            NoPoopCheckIn(day: completedDay, reportedAt: occurrence("2026-10-20T12:00:00Z", zone), coverage: .completed),
            NoPoopCheckIn(day: partialDay, reportedAt: occurrence("2026-10-05T09:00:00Z", zone), coverage: .partial),
        ]

        let data = try HistoryViewModel.viewData(HistorySourceData(
            entries: entries, checkIns: checkIns, month: today, selectedDay: loggedDay,
            today: today, timeZone: zone
        ))
        let days = Dictionary(uniqueKeysWithValues: data.calendar.days.compactMap(\.self).map { ($0.dayID, $0.mark) })
        #expect(days["2026-10-03"] == .logs(2))
        #expect(days["2026-10-04"] == .noPoop)
        #expect(days["2026-10-05"] == .unrecorded)
        #expect(days["2026-10-06"] == .unrecorded)
        #expect(days["2026-10-20"] == .open)
        #expect(days["2026-10-21"] == .future)
        #expect(Self.entries(data.selected)?.count == 2)
        #expect(data.selected.countLabel == "2 logs")
        #expect(data.logSummary == "2 logs in October")
        #expect(data.unrecorded == HistoryUnrecordedViewData(dayID: "2026-10-05", label: "15 days not recorded"))
        #expect(days["2026-10-02"] == .untracked)
    }

    @Test func historyGroupsEntriesByStoredOccurrenceLocalDay() throws {
        let occurrenceZone = try #require(TimeZone(secondsFromGMT: 8 * 60 * 60))
        let displayZone = try #require(TimeZone(secondsFromGMT: 0))
        let entry = try entry(day: DiaryDay(date: date("2026-10-20T18:00:00Z"), timeZone: occurrenceZone), hour: 23)
        let storedDay = DiaryDay(occurrence: entry.occurrence)
        let data = try HistoryViewModel.viewData(HistorySourceData(
            entries: [entry], checkIns: [], month: date("2026-10-15T12:00:00Z"), selectedDay: storedDay,
            today: date("2026-10-30T12:00:00Z"), timeZone: displayZone
        ))
        #expect(Self.entries(data.selected)?.count == 1)
    }

    @Test func selectionMonthNavigationTodayAndFutureDatesStayBounded() throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        var clock = try date("2026-10-20T12:00:00Z")
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: fixture()))
        let model = try HistoryViewModel(
            repository: repository,
            undoModel: UndoModel(repository: repository),
            now: { clock },
            timeZone: { zone }
        )
        model.load()
        #expect(Self.loaded(model.state)?.selected.dayID == "2026-10-20")
        #expect(Self.loaded(model.state)?.isShowingToday == true)
        model.moveMonth(-1)
        #expect(Self.loaded(model.state)?.isShowingToday == false)
        #expect(Self.loaded(model.state)?.monthLabel == "September 2026")
        #expect(Self.loaded(model.state)?.selected.dayID == "2026-09-20")
        model.moveMonth(1)
        #expect(Self.loaded(model.state)?.monthLabel == "October 2026")
        let october20 = "2026-10-20"
        model.select(id: "2026-10-21")
        #expect(Self.loaded(model.state)?.selected.dayID == october20)
        model.select(id: "2026-09-30")
        #expect(Self.loaded(model.state)?.selected.dayID == october20)
        clock = try date("2026-10-21T12:00:00Z")
        model.showToday()
        #expect(Self.loaded(model.state)?.selected.dayID == "2026-10-21")
        #expect(Self.loaded(model.state)?.isShowingToday == true)
    }

    @Test func saveDeleteAndUndoKeepTheSelectedHistoryDay() throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let clock = try date("2026-10-20T12:00:00Z")
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: fixture()))
        let undo = UndoModel(repository: repository)
        let model = try HistoryViewModel(repository: repository, undoModel: undo, now: { clock }, timeZone: { zone })
        model.select(id: "2026-10-03")
        model.addEntry()
        let editor = try #require(model.editor)
        try editor.setDate(date("2026-10-03T08:00:00Z"))
        editor.pickRequiredObservations()
        #expect(editor.save())
        model.savedEditor()
        #expect(Self.loaded(model.state)?.selected.dayID == "2026-10-03")
        #expect(try repository.entries().count == 1)
        let entry = try #require(try repository.entries().first)
        #expect(model.delete(id: entry.id))
        #expect(Self.loaded(model.state)?.selected.dayID == "2026-10-03")
        undo.undo()
        model.load()
        #expect(Self.loaded(model.state)?.selected.dayID == "2026-10-03")
        #expect(try repository.entries().count == 1)
    }

    @Test func emptyDaysOfferTheSameCardAsTodayAndTodayStaysOpen() throws {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let today = try date("2026-10-20T12:00:00Z")
        let pastDay = try DiaryDay(date: date("2026-10-06T00:00:00Z"), timeZone: zone)
        let past = try HistoryViewModel.viewData(HistorySourceData(
            entries: [], checkIns: [], month: today, selectedDay: pastDay, today: today, timeZone: zone
        ))
        guard case let .pastDay(status, _, logLabel, canConfirm, mark) = past.selected.content else {
            Issue.record("expected the not-recorded card")
            return
        }
        #expect(status == "Not recorded")
        #expect(logLabel == "Log for Tue")
        #expect(canConfirm)
        #expect(mark == .unrecorded)
        #expect(past.selected.countLabel == nil)
        #expect(past.logSummary == "0 logs in October")

        let open = try HistoryViewModel.viewData(HistorySourceData(
            entries: [], checkIns: [], month: today, selectedDay: DiaryDay(date: today, timeZone: zone),
            today: today, timeZone: zone
        ))
        #expect(open.selected.content == .open(logLabel: "Log for Tuesday"))
    }

    private static func entries(_ selection: HistorySelectionViewData) -> [TodayEntryViewData]? {
        guard case let .entries(entries, _) = selection.content else { return nil }
        return entries
    }

    private static func loaded(_ state: Loadable<HistoryViewData>) -> HistoryViewData? {
        guard case let .loaded(data) = state else { return nil }
        return data
    }

    private func entry(day: DiaryDay, hour: Int) throws -> DiaryEntry {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        let occurrence = try OccurrenceTime(
            instant: date(String(format: "%04d-%02d-%02dT%02d:00:00Z", day.year, day.month, day.day, hour)),
            timeZone: zone
        )
        return DiaryEntry(id: UUID(), occurrence: occurrence, stoolType: 4, amount: nil, effort: nil, note: "")
    }

    private func occurrence(_ value: String, _ zone: TimeZone) throws -> OccurrenceTime {
        try OccurrenceTime(instant: date(value), timeZone: zone)
    }

    private func date(_ value: String) throws -> Date {
        guard let date = ISO8601DateFormatter().date(from: value) else { throw AppError.invalidOccurrence }
        return date
    }

    private func fixture() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    }
}
