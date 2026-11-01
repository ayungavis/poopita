import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct TodayFlowTests {
    @Test func defaultComposerSavesReopensAndNeverInheritsOptionalChoices() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let date = Date(timeIntervalSince1970: 1_792_800_000)
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let undo = UndoModel(repository: repository)
        let model = TodayViewModel(repository: repository, undoModel: undo, now: { date }, timeZone: { .gmt })
        model.load()
        await model.loadTask?.value
        let composer = try #require(model.composer)
        #expect(composer.draft.occurrenceDate == date)
        #expect(composer.draft.stoolType == nil && composer.draft.amount == nil && composer.draft.effort == nil)
        composer.setAmount("small")
        composer.setEffort("moderate")
        composer.setNote("remember")
        composer.pickRequiredObservations()
        #expect(composer.save())
        model.savedComposer()
        await model.loadTask?.value
        let next = try #require(model.composer)
        #expect(next.id != composer.id)
        #expect(next.draft.stoolType == nil && next.draft.amount == nil && next.draft.effort == nil)
        #expect(next.draft.note.isEmpty)
        guard case let .loaded(data) = model.state else { Issue.record("Expected loaded diary"); return }
        let logged = data.timeline.blocks.map(\.entry)
        #expect(logged.count == 1)
        #expect(!logged[0].timeLabel.isEmpty)
        #expect(logged[0].observations.contains("Small"))
        let reopened = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        #expect(try reopened.entries().first?.note == "remember")
        model.edit(id: composer.id)
        let editor = try #require(model.editor)
        #expect(editor.isEditing)
        editor.setAmount("large")
        #expect(editor.draft.effort == "moderate" && editor.draft.note == "remember")
        #expect(editor.save())
        model.savedEditor()
        await model.loadTask?.value
        #expect(try repository.entries().first?.amount == .large)
        undo.undo()
        model.load()
        await model.loadTask?.value
        #expect(try repository.entries().first?.amount == .small)
        #expect(model.delete(id: composer.id))
        await model.loadTask?.value
        #expect(try repository.entries().isEmpty)
        undo.undo()
        model.load()
        await model.loadTask?.value
        #expect(try repository.entries().count == 1)
    }

    @Test func refreshesAnUntouchedClockButPreservesAManualDraft() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        var clock = Date(timeIntervalSince1970: 1_792_800_000)
        let model = TodayViewModel(
            repository: repository,
            undoModel: UndoModel(repository: repository),
            now: { clock },
            timeZone: { .gmt }
        )
        model.load()
        await model.loadTask?.value
        clock = clock.addingTimeInterval(3600)
        model.load()
        await model.loadTask?.value
        let composer = try #require(model.composer)
        #expect(composer.draft.occurrenceDate == clock)
        composer.setNote("preserve my draft")
        let manual = composer.draft
        clock = clock.addingTimeInterval(3600)
        model.load()
        await model.loadTask?.value
        #expect(model.composer?.draft == manual)
        #expect(model.composer?.id == composer.id)
    }

    @Test func failedOrFutureSaveKeepsDraftAndDoesNotClaimSuccess() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let date = Date(timeIntervalSince1970: 1_792_800_000)
        let store = try SwiftDataValueStore(directory: directory, commit: { _ in throw CocoaError(.fileWriteOutOfSpace) })
        let repository = LocalDiaryRepository(store: store)
        let undo = UndoModel(repository: repository)
        let model = TodayViewModel(repository: repository, undoModel: undo, now: { date }, timeZone: { .gmt })
        model.load()
        await model.loadTask?.value
        let composer = try #require(model.composer)
        composer.setNote("keep my draft")
        composer.pickRequiredObservations()
        #expect(!composer.save())
        #expect(composer.draft.note == "keep my draft")
        #expect(undo.toast == nil)
        #expect(composer.error == .storageWrite)
        composer.setDate(date.addingTimeInterval(1))
        #expect(!composer.save())
        #expect(composer.error == .invalidOccurrence)
        #expect(try repository.entries().isEmpty)
    }

    @Test func tabBarLogActionPresentsTheExistingComposer() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let now = Date(timeIntervalSince1970: 1_792_800_000)
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let model = TodayViewModel(
            repository: repository,
            undoModel: UndoModel(repository: repository),
            now: { now },
            timeZone: { .gmt }
        )

        model.load()
        await model.loadTask?.value
        model.presentLogSheet()

        let editor = try #require(model.editor)
        #expect(editor.id == model.composer?.id)
        #expect(!editor.isEditing)
    }

    @Test func todayShowsTimeSinceLatestEntryWhenThereIsNoEntryToday() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let now = Date(timeIntervalSince1970: 1_792_800_000)
        let previous = try DiaryEntry(
            id: UUID(),
            occurrence: OccurrenceTime(instant: now.addingTimeInterval(-2 * 86400 - 3 * 3600), timeZone: .gmt),
            stoolType: nil,
            amount: nil,
            effort: nil,
            note: ""
        )
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        try repository.save(previous)
        let model = TodayViewModel(
            repository: repository,
            undoModel: UndoModel(repository: repository),
            now: { now },
            timeZone: { .gmt }
        )

        model.load()
        await model.loadTask?.value

        guard case let .loaded(data) = model.state else { Issue.record("Expected loaded diary"); return }
        #expect(data.timeline.blocks.isEmpty)
        guard case let .waiting(headline, detail, _) = data.dayState else { Issue.record("Expected waiting"); return }
        #expect(headline.contains("2 days"))
        #expect(headline.contains("3 hours"))
        #expect(detail?.hasPrefix("since your last log") == true)
    }

    @Test func weekStripContainsSevenDaysAndDayStateUpdatesOnSelection() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let date = Date(timeIntervalSince1970: 1_792_800_000)
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let model = TodayViewModel(
            repository: repository,
            undoModel: UndoModel(repository: repository),
            now: { date },
            timeZone: { .gmt }
        )
        model.load()
        await model.loadTask?.value
        guard case let .loaded(data) = model.state else { Issue.record("Expected loaded diary"); return }
        #expect(data.weekDays.count == 7)
        let foundToday = data.weekDays.first(where: { $0.isToday })
        let todayItem = try #require(foundToday)
        #expect(todayItem.isSelected)
        #expect(data.dayState == .waiting(headline: "Nothing logged yet", detail: nil, partialNote: nil))

        let composer = try #require(model.composer)
        composer.pickRequiredObservations()
        #expect(composer.save())
        model.savedComposer()
        await model.loadTask?.value
        guard case let .loaded(updated) = model.state else { Issue.record("Expected loaded diary"); return }
        #expect(updated.dayState == .logged)
        #expect(updated.timeline.blocks.count == 1)

        let yesterday = data.weekDays.first(where: { !$0.isToday })
        if let yesterday {
            model.selectDay(id: yesterday.dayID)
            await model.loadTask?.value
            guard case let .loaded(pastData) = model.state else { Issue.record("Expected loaded diary"); return }
            let foundSelected = pastData.weekDays.first(where: { $0.dayID == yesterday.dayID })
            let selectedItem = try #require(foundSelected)
            #expect(selectedItem.isSelected)
            #expect(pastData.timeline.blocks.isEmpty)
        }
    }
}
