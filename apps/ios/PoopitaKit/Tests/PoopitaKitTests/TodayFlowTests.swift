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
        let model = TodayViewModel(repository: repository, now: { date }, timeZone: { .gmt })
        model.load()
        await model.loadTask?.value
        let composer = try #require(model.composer)
        #expect(composer.draft.occurrenceDate == date)
        #expect(composer.draft.stoolType == nil && composer.draft.amount == nil && composer.draft.effort == nil)
        composer.setAmount("small")
        composer.setEffort("moderate")
        composer.setNote("remember")
        #expect(composer.save())
        model.savedComposer()
        await model.loadTask?.value
        let next = try #require(model.composer)
        #expect(next.id != composer.id)
        #expect(next.draft.stoolType == nil && next.draft.amount == nil && next.draft.effort == nil)
        #expect(next.draft.note.isEmpty)
        guard case let .loaded(data) = model.state else { Issue.record("Expected loaded diary"); return }
        #expect(data.entries.count == 1)
        #expect(!data.entries[0].timeLabel.isEmpty)
        #expect(data.entries[0].observations.contains("Small"))
        let reopened = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        #expect(try reopened.entries().first?.note == "remember")
        model.edit(id: composer.id)
        let editor = try #require(model.editor)
        #expect(editor.isEditing)
        editor.setAmount(nil)
        #expect(editor.draft.effort == "moderate" && editor.draft.note == "remember")
        #expect(editor.save())
        model.savedEditor()
        await model.loadTask?.value
        #expect(try repository.entries().first?.amount == nil)
        model.undo()
        await model.loadTask?.value
        #expect(try repository.entries().first?.amount == .small)
        #expect(model.delete(id: composer.id))
        await model.loadTask?.value
        #expect(try repository.entries().isEmpty)
        model.undo()
        await model.loadTask?.value
        #expect(try repository.entries().count == 1)
    }

    @Test func refreshesAnUntouchedClockButPreservesAManualDraft() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        var clock = Date(timeIntervalSince1970: 1_792_800_000)
        let model = TodayViewModel(repository: repository, now: { clock }, timeZone: { .gmt })
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
        let model = TodayViewModel(repository: repository, now: { date }, timeZone: { .gmt })
        model.load()
        await model.loadTask?.value
        let composer = try #require(model.composer)
        composer.setNote("keep my draft")
        #expect(!composer.save())
        #expect(composer.draft.note == "keep my draft")
        #expect(model.feedback == nil)
        #expect(composer.error == .storageWrite)
        composer.setDate(date.addingTimeInterval(1))
        #expect(!composer.save())
        #expect(composer.error == .invalidOccurrence)
        #expect(try repository.entries().isEmpty)
    }
}
