import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct UndoModelTests {
    @Test func aSavedChangeOffersUndoAndUndoRestoresTheDiary() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let model = UndoModel(repository: repository)
        try repository.save(DiaryPersistenceTests.entry(note: "first"))

        model.record("Entry saved")
        #expect(model.toast?.message == "Entry saved")
        #expect(model.toast?.canUndo == true)

        model.undo()

        #expect(try repository.entries().isEmpty)
        #expect(model.revision == 1)
        #expect(model.toast?.message == "Change undone")
        #expect(model.toast?.canUndo == false)
    }

    @Test func aNewerMessageReplacesTheOlderOneAndAStaleDismissKeepsIt() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let model = UndoModel(repository: repository)

        model.record("App lock on", undoable: false)
        let older = try #require(model.toast)
        #expect(!older.canUndo)
        try repository.save(DiaryPersistenceTests.entry(note: "first"))
        model.record("Entry saved")
        model.dismiss(id: older.id)

        #expect(model.toast?.message == "Entry saved")
        try model.dismiss(id: #require(model.toast).id)
        #expect(model.toast == nil)
    }

    @Test func undoAfterAnotherChangeFailsWithoutTouchingTheDiary() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let first = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let second = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let model = UndoModel(repository: first)
        try first.save(DiaryPersistenceTests.entry(note: "first"))
        model.record("Entry saved")
        try second.save(DiaryPersistenceTests.entry(note: "second"))

        model.undo()

        #expect(try first.entries().count == 2)
        #expect(model.revision == 0)
        #expect(model.toast?.staysUntilDismissed == true)
        #expect(model.toast?.canUndo == false)
    }
}
