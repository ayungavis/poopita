import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct CheckInFlowTests {
    @Test func partialCheckInReopensAndAnEntryAtomicallyReplacesItWithUndo() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let entry = try DiaryPersistenceTests.entry(note: "correction")
        let checkIn = NoPoopCheckIn(
            day: DiaryDay(occurrence: entry.occurrence), reportedAt: entry.occurrence, coverage: .partial
        )
        try repository.saveCheckIn(checkIn)
        let reopened = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        #expect(try reopened.checkIns() == [checkIn])
        #expect(!reopened.canUndo)
        try reopened.save(entry)
        #expect(try reopened.checkIns().isEmpty)
        #expect(try reopened.entries() == [entry])
        #expect(throws: AppError.self) { try reopened.saveCheckIn(checkIn) }
        try reopened.undo()
        #expect(try reopened.checkIns() == [checkIn])
        #expect(try reopened.entries().isEmpty)
        try reopened.save(entry)
        try reopened.delete(id: entry.id)
        #expect(try reopened.checkIns().isEmpty)
        #expect(try reopened.entries().isEmpty)
    }

    @Test func completedDayRequiresAnExplicitLaterReportAndDoesNotRewriteOtherDays() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let report = try OccurrenceTime(instant: Date(timeIntervalSince1970: 1_793_511_000), timeZone: .gmt)
        let yesterday = try DiaryDay(date: report.instant.addingTimeInterval(-86400), timeZone: .gmt)
        let invalid = try [
            NoPoopCheckIn(day: DiaryDay(occurrence: report), reportedAt: report, coverage: .completed),
            NoPoopCheckIn(day: yesterday, reportedAt: report, coverage: .partial),
            NoPoopCheckIn(day: DiaryDay(date: report.instant.addingTimeInterval(86400), timeZone: .gmt),
                          reportedAt: report, coverage: .completed),
        ]
        for checkIn in invalid {
            #expect(throws: AppError.self) { try repository.saveCheckIn(checkIn) }
        }
        let partial = try NoPoopCheckIn(day: yesterday, reportedAt: OccurrenceTime(
            instant: report.instant.addingTimeInterval(-86400), timeZone: .gmt
        ), coverage: .partial)
        try repository.saveCheckIn(partial)
        #expect(try repository.checkIns() == [partial])
        let completed = NoPoopCheckIn(day: yesterday, reportedAt: report, coverage: .completed)
        try repository.saveCheckIn(completed)
        #expect(try repository.checkIns() == [completed])
        try repository.undo()
        #expect(try repository.checkIns() == [partial])
        #expect(try repository.checkIns() == [partial])
    }

    @Test func failedCommitKeepsCheckInAndUndoUntilCorrectionSucceeds() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        var commits = 0
        let store = try SwiftDataValueStore(directory: directory, commit: { context in
            commits += 1
            if commits == 2 {
                throw CocoaError(.fileWriteOutOfSpace)
            }
            try context.save()
        })
        let repository = LocalDiaryRepository(store: store)
        let entry = try DiaryPersistenceTests.entry(note: "preserve")
        let checkIn = NoPoopCheckIn(day: DiaryDay(occurrence: entry.occurrence),
                                    reportedAt: entry.occurrence, coverage: .partial)
        try repository.saveCheckIn(checkIn)
        #expect(throws: AppError.storageWrite) { try repository.save(entry) }
        #expect(try repository.checkIns() == [checkIn])
        #expect(try repository.entries().isEmpty)
        #expect(repository.canUndo)
        let reopened = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        #expect(try reopened.checkIns() == [checkIn])
        try repository.undo()
        #expect(try repository.checkIns().isEmpty)
    }

    @Test func legacyEntriesMigrateWithoutLossAndMalformedNewSnapshotsAreRejected() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let store = try SwiftDataValueStore(directory: directory)
        let entry = try DiaryPersistenceTests.entry(note: "legacy")
        try store.write(LegacyDiaryFixture(version: 1, entries: [entry]), key: "diary")
        let repository = LocalDiaryRepository(store: store)
        #expect(try repository.entries() == [entry])
        #expect(try repository.checkIns().isEmpty)
        let report = try OccurrenceTime(instant: entry.occurrence.instant.addingTimeInterval(86400), timeZone: .gmt)
        let checkIn = NoPoopCheckIn(day: DiaryDay(occurrence: report), reportedAt: report, coverage: .partial)
        try repository.saveCheckIn(checkIn)
        let reopened = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        #expect(try reopened.entries() == [entry])
        #expect(try reopened.checkIns() == [checkIn])
        let malformed = LegacyDiaryFixture(version: 2, entries: [entry])
        try store.write(malformed, key: "diary")
        #expect(throws: AppError.invalidStoredData) { try repository.entries() }
        #expect(try store.read(LegacyDiaryFixture.self, key: "diary") == malformed)
    }

    @Test func failedLoadExposesTypedLoadableFailure() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let store = try SwiftDataValueStore(directory: directory)
        try store.write(LegacyDiaryFixture(version: 3, entries: []), key: "diary")
        let model = try CheckInViewModel(
            repository: LocalDiaryRepository(store: store), now: { .now }, timeZone: { .current }
        )
        #expect(throws: AppError.invalidStoredData) { try model.load() }
        #expect(model.state == .failed(.invalidStoredData))
    }

    private static func data(_ state: Loadable<CheckInViewData>) -> CheckInViewData? {
        guard case let .loaded(data) = state else { return nil }
        return data
    }

    @Test func anOldPartialCheckInReadsAsNotRecordedUntilConfirmedAndCancellationWritesNothing() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let zone = try #require(TimeZone(identifier: "Asia/Makassar"))
        var clock = try #require(ISO8601DateFormatter().date(from: "2026-10-25T23:59:00+08:00"))
        let model = try CheckInViewModel(repository: repository, now: { clock }, timeZone: { zone })
        try model.load()
        #expect(Self.data(model.state)?.today.status == "Not recorded")
        let cancelled = Task { model.confirmSelectedDay() }
        cancelled.cancel()
        #expect(await cancelled.value == false)
        #expect(try repository.checkIns().isEmpty)
        let report = try OccurrenceTime(instant: clock, timeZone: zone)
        let partial = NoPoopCheckIn(day: DiaryDay(occurrence: report), reportedAt: report, coverage: .partial)
        try repository.saveCheckIn(partial)
        try model.load()
        #expect(Self.data(model.state)?.today.status == "Not recorded")
        clock = clock.addingTimeInterval(120)
        try model.load()
        #expect(Self.data(model.state)?.today.status == "Not recorded")
        #expect(try repository.checkIns() == [partial])
        model.selectDate(partial.reportedAt.instant)
        #expect(Self.data(model.state)?.selected.status == "Not recorded")
        #expect(Self.data(model.state)?.selected.canRecord == true)
        #expect(model.confirmSelectedDay())
        try model.load()
        #expect(Self.data(model.state)?.selected.status == "No poop that day")
        #expect(try repository.checkIns().first?.coverage == .completed)
        model.selectDate(clock)
        #expect(!model.confirmSelectedDay())
        model.selectDate(clock.addingTimeInterval(86400))
        #expect(!model.confirmSelectedDay())
        try repository.undo()
        #expect(try repository.checkIns() == [partial])
    }

    @Test func checkInWriteFailureRetainsSelectionAndDoesNotConsumeUndo() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        var commits = 0
        let store = try SwiftDataValueStore(directory: directory, commit: { context in
            commits += 1
            if commits == 2 {
                throw CocoaError(.fileWriteOutOfSpace)
            }
            try context.save()
        })
        let repository = LocalDiaryRepository(store: store)
        let date = Date(timeIntervalSince1970: 1_793_511_000)
        let model = try CheckInViewModel(repository: repository, now: { date }, timeZone: { .gmt })
        try model.load()
        let report = try OccurrenceTime(instant: date, timeZone: .gmt)
        try repository.saveCheckIn(NoPoopCheckIn(day: DiaryDay(occurrence: report), reportedAt: report, coverage: .partial))
        let selection = model.selectedDate
        #expect(!model.confirmSelectedDay())
        #expect(model.errorMessage == AppError.storageWrite.userMessage)
        #expect(model.selectedDate == selection)
        #expect(repository.canUndo)
        #expect(try repository.checkIns().count == 1)
        try repository.undo()
        #expect(try repository.checkIns().isEmpty)
    }

    @Test func nativeComposerReportsDayUpdatedAndMovingAnEntryRestoresBothDaysOnUndo() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let date = Date(timeIntervalSince1970: 1_793_511_000)
        let undo = UndoModel(repository: repository)
        let model = TodayViewModel(repository: repository, undoModel: undo, now: { date }, timeZone: { .gmt })
        model.load()
        await model.loadTask?.value
        let report = try OccurrenceTime(instant: date, timeZone: .gmt)
        try repository.saveCheckIn(NoPoopCheckIn(day: DiaryDay(occurrence: report), reportedAt: report, coverage: .partial))
        model.load()
        await model.loadTask?.value
        let checkIn = try #require(try repository.checkIns().first)
        let composer = try #require(model.composer)
        composer.pickRequiredObservations()
        #expect(composer.save())
        model.savedComposer()
        await model.loadTask?.value
        #expect(undo.toast?.message == "Day updated")
        #expect(try repository.checkIns().isEmpty)
        undo.undo()
        model.load()
        await model.loadTask?.value
        #expect(try repository.checkIns() == [checkIn])
        #expect(try repository.entries().isEmpty)
        let yesterday = try OccurrenceTime(instant: date.addingTimeInterval(-86400), timeZone: .gmt)
        let entry = DiaryEntry(id: UUID(), occurrence: yesterday, stoolType: nil, amount: nil, effort: nil, note: "move")
        try repository.save(entry)
        model.edit(id: entry.id)
        let editor = try #require(model.editor)
        editor.setDate(date)
        editor.pickRequiredObservations()
        #expect(editor.save())
        model.savedEditor()
        await model.loadTask?.value
        #expect(undo.toast?.message == "Day updated")
        #expect(try repository.checkIns().isEmpty)
        undo.undo()
        model.load()
        await model.loadTask?.value
        #expect(try repository.entries() == [entry])
        #expect(try repository.checkIns() == [checkIn])
    }

    @Test func rejectsContradictoryDuplicateAndMalformedStoredCheckInsWithoutOverwriting() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let store = try SwiftDataValueStore(directory: directory)
        let repository = LocalDiaryRepository(store: store)
        let entry = try DiaryPersistenceTests.entry(note: "keep")
        let checkIn = NoPoopCheckIn(day: DiaryDay(occurrence: entry.occurrence),
                                    reportedAt: entry.occurrence, coverage: .partial)
        let invalidDay = try JSONDecoder().decode(DiaryDay.self, from: Data(
            #"{"year":2026,"month":2,"day":31}"#.utf8
        ))
        let invalidDate = NoPoopCheckIn(day: invalidDay, reportedAt: entry.occurrence, coverage: .completed)
        let invalidCoverage = NoPoopCheckIn(day: checkIn.day, reportedAt: entry.occurrence, coverage: .completed)
        let fixtures = [
            CheckInSnapshotFixture(version: 2, entries: [entry], checkIns: [checkIn]),
            CheckInSnapshotFixture(version: 2, entries: [], checkIns: [checkIn, checkIn]),
            CheckInSnapshotFixture(version: 2, entries: [], checkIns: [invalidDate]),
            CheckInSnapshotFixture(version: 2, entries: [], checkIns: [invalidCoverage]),
            CheckInSnapshotFixture(version: 1, entries: [], checkIns: [checkIn]),
        ]
        for fixture in fixtures {
            try store.write(fixture, key: "diary")
            #expect(throws: AppError.invalidStoredData) { try repository.checkIns() }
            #expect(throws: AppError.invalidStoredData) { try repository.save(entry) }
            #expect(try store.read(CheckInSnapshotFixture.self, key: "diary") == fixture)
            #expect(!repository.canUndo)
        }
    }
}

private struct LegacyDiaryFixture: Codable, Equatable {
    let version: Int
    let entries: [DiaryEntry]
}

private struct CheckInSnapshotFixture: Codable, Equatable {
    let version: Int
    let entries: [DiaryEntry]
    let checkIns: [NoPoopCheckIn]
}
