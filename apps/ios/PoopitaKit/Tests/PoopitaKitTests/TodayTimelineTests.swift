import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct TodayTimelineTests {
    private static let now = Date(timeIntervalSince1970: 1_793_439_660)
    private static let day: TimeInterval = 86400

    private static func entry(_ offset: TimeInterval, type: Int = 4) throws -> DiaryEntry {
        try DiaryEntry(
            id: UUID(), occurrence: OccurrenceTime(instant: now.addingTimeInterval(offset), timeZone: .gmt),
            stoolType: type, amount: .small, effort: .easy, blood: DiaryEntry.Blood.none, note: ""
        )
    }

    private static func week() throws -> (entries: [DiaryEntry], checkIns: [NoPoopCheckIn]) {
        let entries = try [
            entry(-5 * day + 1140),
            entry(-4 * day - 6060),
            entry(-4 * day + 37140),
            entry(-10560, type: 3),
            entry(-5460),
        ]
        let checkIns = try [
            NoPoopCheckIn(
                day: DiaryDay(year: 2026, month: 10, day: 28),
                reportedAt: OccurrenceTime(instant: now, timeZone: .gmt), coverage: .completed
            ),
            NoPoopCheckIn(
                day: DiaryDay(year: 2026, month: 10, day: 30),
                reportedAt: OccurrenceTime(instant: now.addingTimeInterval(-day + 37140), timeZone: .gmt),
                coverage: .partial
            ),
        ]
        return (entries, checkIns)
    }

    private static func makeModel(_ directory: URL) throws -> (TodayViewModel, LocalDiaryRepository) {
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let (entries, checkIns) = try week()
        for entry in entries {
            try repository.save(entry)
        }
        for checkIn in checkIns {
            try repository.saveCheckIn(checkIn)
        }
        return (TodayViewModel(repository: repository, now: { now }, timeZone: { .gmt }), repository)
    }

    @Test func weekStripKeepsUnknownDaysApartFromConfirmedAndPartialOnes() throws {
        let (entries, checkIns) = try Self.week()
        let data = try TodayViewModel.viewData(
            entries: entries, checkIns: checkIns, date: Self.now, timeZone: .gmt, canUndo: false
        )

        #expect(data.weekDays.map(\.mark) == [.logs(1), .logs(2), .noPoop, .unrecorded, .noneSoFar, .logs(2), .future])
        #expect(data.weekDays.map(\.dayNumber) == ["26", "27", "28", "29", "30", "31", "1"])
        #expect(data.weekSummary == "5 logs this week")
        #expect(data.fillIn?.dayID == "2026-10-29")
        #expect(data.fillIn?.label == "Fill in Thursday")
        #expect(data.title == "Today")
        #expect(data.dayNumber == "31")
        #expect(TodayViewModel.logCount(1) == "1 log")
    }

    @Test func timelinePlacesLogsAtTheirTimeAndMeasuresFromTheLastOne() throws {
        let (entries, checkIns) = try Self.week()
        let data = try TodayViewModel.viewData(
            entries: entries, checkIns: checkIns, date: Self.now, timeZone: .gmt, canUndo: false
        )
        let timeline = data.timeline

        #expect(data.dayState == .logged)
        #expect(timeline.hours.map(\.minute) == Array(stride(from: 0, through: 420, by: 60)))
        #expect(timeline.endMinute == 480)
        #expect(timeline.blocks.map(\.minute) == [45, 130])
        #expect(timeline.blocks.first?.entry.title == "Type 3 · Cracked")
        #expect(timeline.now?.minute == 221)
        let since = try #require(timeline.sinceLast)
        #expect(since.minute == 130)
        #expect(since.label.hasPrefix("Since "))
        #expect(since.label.contains(timeline.blocks[1].entry.timeLabel))
    }

    @Test func aPastDayWithNothingRecordedOffersLogAndConfirmWithoutGuessing() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let (model, repository) = try Self.makeModel(directory)
        model.load()
        await model.loadTask?.value

        model.selectDay(id: "2026-10-29")
        await model.loadTask?.value
        guard case let .loaded(data) = model.state else { Issue.record("Expected loaded diary"); return }
        guard case let .pastDay(status, _, logLabel, canConfirm) = data.dayState else {
            Issue.record("Expected a past-day card"); return
        }
        #expect(status == "Not recorded")
        #expect(logLabel == "Log for Thursday")
        #expect(canConfirm)
        #expect(data.title == "Thursday")

        model.presentLogForSelectedDay()
        let editor = try #require(model.editor)
        #expect(editor.draft.occurrenceDate == Self.now.addingTimeInterval(-2 * Self.day))
        model.dismissEditor()

        model.confirmNoPoopForSelectedDay()
        await model.loadTask?.value
        #expect(try repository.checkIns().contains { $0.day.id == "2026-10-29" && $0.coverage == .completed })
        guard case let .loaded(confirmed) = model.state else { Issue.record("Expected loaded diary"); return }
        #expect(confirmed.weekDays[3].mark == .noPoop)
        #expect(confirmed.fillIn == nil)
    }

    @Test func aPartialPastDayStaysPartialUntilTheUserConfirmsIt() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let (model, _) = try Self.makeModel(directory)
        model.load()
        await model.loadTask?.value

        model.selectDay(id: "2026-10-30")
        await model.loadTask?.value
        guard case let .loaded(data) = model.state else { Issue.record("Expected loaded diary"); return }
        guard case let .pastDay(status, _, _, canConfirm) = data.dayState else {
            Issue.record("Expected a past-day card"); return
        }
        #expect(status == "Partial check-in")
        #expect(canConfirm)
        #expect(data.weekDays[4].mark == .noneSoFar)
    }

    @Test func todayWithoutLogsCountsUpAndRecordsAPartialCheckIn() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        try repository.save(Self.entry(-3 * Self.day - 45360))
        let model = TodayViewModel(repository: repository, now: { Self.now }, timeZone: { .gmt })
        model.load()
        await model.loadTask?.value
        guard case let .loaded(data) = model.state,
              case let .waiting(headline, detail, partialNote) = data.dayState
        else { Issue.record("Expected the waiting state"); return }
        #expect(headline.contains("3 days") && headline.contains("12 hours"))
        #expect(detail?.hasPrefix("since your last log, Tuesday at ") == true)
        #expect(partialNote == nil)

        model.recordCheckInToday()
        await model.loadTask?.value
        guard case let .loaded(updated) = model.state,
              case let .waiting(_, _, note) = updated.dayState
        else { Issue.record("Expected the waiting state"); return }
        #expect(note != nil)
        #expect(updated.weekDays[5].mark == .noneSoFar)
    }

    @Test func futureDaysCannotBeSelected() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let (model, _) = try Self.makeModel(directory)
        model.load()
        await model.loadTask?.value

        model.selectDay(id: "2026-11-01")
        await model.loadTask?.value

        guard case let .loaded(data) = model.state else { Issue.record("Expected loaded diary"); return }
        #expect(data.weekDays.first { $0.isSelected }?.dayID == "2026-10-31")
    }
}
