import Foundation
@testable import PoopitaKit
import SwiftData
import Testing

@MainActor
struct DiaryPersistenceTests {
    @Test func savesCorrectsDeletesAndUndoesAcrossRealStoreReopening() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { Self.removeFixture(directory) }
        let entry = try Self.entry(note: "original")
        do {
            let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
            try repository.save(entry)
            #expect(repository.canUndo)
        }
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        #expect(try repository.entries() == [entry])
        #expect(!repository.canUndo)
        let corrected = DiaryEntry(
            id: entry.id, occurrence: entry.occurrence, stoolType: nil,
            amount: nil, effort: .easy, note: "corrected"
        )
        try repository.save(corrected)
        #expect(try repository.entries() == [corrected])
        try repository.undo()
        #expect(try repository.entries() == [entry])
        #expect(!repository.canUndo)
        try repository.delete(id: entry.id)
        #expect(try repository.entries().isEmpty)
        try repository.undo()
        #expect(try repository.entries() == [entry])
        let reopened = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        #expect(try reopened.entries() == [entry])
    }

    @Test func failedValidationPreservesRecordsAndThePreviousUndo() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { Self.removeFixture(directory) }
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let entry = try Self.entry(note: String(repeating: "👨‍👩‍👧‍👦", count: 500))
        try repository.save(entry)
        let invalid = DiaryEntry(
            id: entry.id, occurrence: entry.occurrence, stoolType: 8,
            amount: nil, effort: nil, note: "invalid"
        )
        #expect(throws: AppError.invalidObservation) { try repository.save(invalid) }
        let tooLong = try Self.entry(note: String(repeating: "👨‍👩‍👧‍👦", count: 501))
        #expect(throws: AppError.noteTooLong) { try repository.save(tooLong) }
        #expect(try repository.entries() == [entry])
        #expect(repository.canUndo)
        try repository.undo()
        #expect(try repository.entries().isEmpty)
    }

    @Test func retainsTheOriginalLocalDayAndDistinguishesRepeatedDSTTimes() throws {
        let zone = try #require(TimeZone(identifier: "America/New_York"))
        let first = try OccurrenceTime(instant: Date(timeIntervalSince1970: 1_793_511_000), timeZone: zone)
        let second = try OccurrenceTime(instant: Date(timeIntervalSince1970: 1_793_514_600), timeZone: zone)
        #expect(first.hour == 1 && second.hour == 1)
        #expect(first.minute == 30 && second.minute == 30)
        #expect(first.utcOffsetSeconds != second.utcOffsetSeconds)
        #expect(first.instant != second.instant)
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { Self.removeFixture(directory) }
        let store = try SwiftDataValueStore(directory: directory)
        try store.write(first, key: "occurrence")
        let restored = try #require(try store.read(OccurrenceTime.self, key: "occurrence"))
        #expect(restored == first)
        try restored.validate()
        let traveling = try OccurrenceTime(instant: restored.instant, timeZone: .gmt)
        #expect(traveling.hour != restored.hour)
    }

    @Test func rejectsAnUnreadableStoreWithoutReplacingItsFiles() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { Self.removeFixture(directory) }
        let marker = Data("not a database".utf8)
        let file = directory.appending(path: "values.store")
        try marker.write(to: file)
        #expect(throws: AppError.storageUnavailable) { _ = try SwiftDataValueStore(directory: directory) }
        #expect(try Data(contentsOf: file) == marker)
    }

    @Test func failedCommitRetainsDraftDurableDataAndPreviousUndo() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { Self.removeFixture(directory) }
        var commits = 0
        let store = try SwiftDataValueStore(directory: directory, commit: { context in
            commits += 1
            if commits == 2 || commits == 3 {
                throw CocoaError(.fileWriteOutOfSpace)
            }
            try context.save()
        })
        let repository = LocalDiaryRepository(store: store)
        let entry = try Self.entry(note: "first")
        try repository.save(entry)
        let model = try EntryEditorViewModel(
            repository: repository, entryID: entry.id, draft: EntryEditorViewModel.viewData(for: entry),
            now: { entry.occurrence.instant }
        )
        let draft = EntryEditorViewData(
            occurrenceDate: entry.occurrence.instant, timeZoneIdentifier: entry.occurrence.timeZoneIdentifier,
            stoolType: nil, amount: nil, effort: nil, note: "preserve this input"
        )
        model.updateDraft(draft)
        model.save()
        #expect(model.error == .storageWrite)
        #expect(model.draft == draft)
        #expect(model.canUndo)
        #expect(try repository.entries() == [entry])
        let reopened = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        #expect(try reopened.entries() == [entry])
        #expect(throws: AppError.storageWrite) { try repository.undo() }
        #expect(repository.canUndo)
        #expect(try repository.entries() == [entry])
        try repository.undo()
        #expect(try repository.entries().isEmpty)
    }

    @Test func staleUndoCannotOverwriteAnotherRepositoryMutation() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { Self.removeFixture(directory) }
        let first = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let second = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        try first.save(Self.entry(note: "first"))
        try second.save(Self.entry(note: "second"))
        #expect(throws: AppError.conflict) { try first.undo() }
        #expect(try first.entries().count == 2)
    }

    @Test func storeAndSidecarsRequestBackupExclusion() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { Self.removeFixture(directory) }
        let store = try SwiftDataValueStore(directory: directory)
        try store.write("value", key: "test")
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        #expect(!files.isEmpty)
        for file in [directory] + files {
            #expect(try file.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true)
        }
    }

    @Test func editorSavesThroughTheRepositoryAndCancellationLeavesNoRecord() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { Self.removeFixture(directory) }
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let entry = try Self.entry(note: "saved through editor")
        let draft = EntryEditorViewModel.viewData(for: entry)
        let model = try EntryEditorViewModel(
            repository: repository,
            entryID: entry.id,
            draft: draft,
            now: { entry.occurrence.instant }
        )
        let cancelled = Task { model.save() }
        cancelled.cancel()
        _ = await cancelled.value
        #expect(try repository.entries().isEmpty)
        #expect(model.draft == draft)
        #expect(!model.canUndo)
        model.save()
        #expect(model.error == nil)
        let reopened = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        #expect(try reopened.entries() == [entry])
    }

    @Test func unsupportedSnapshotIsRejectedWithoutBeingOverwritten() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { Self.removeFixture(directory) }
        let store = try SwiftDataValueStore(directory: directory)
        let entry = try Self.entry(note: "keep this")
        let future = SnapshotFixture(version: 2, entries: [entry])
        try store.write(future, key: "diary")
        let repository = LocalDiaryRepository(store: store)
        #expect(throws: AppError.invalidStoredData) { try repository.entries() }
        #expect(throws: AppError.invalidStoredData) { try repository.save(entry) }
        #expect(try store.read(SnapshotFixture.self, key: "diary") == future)
        #expect(!repository.canUndo)
    }

    static func removeFixture(_ directory: URL) {
        do {
            try FileManager.default.removeItem(at: directory)
        } catch {
            Issue.record(error)
        }
    }

    static func entry(note: String) throws -> DiaryEntry {
        try DiaryEntry(
            id: UUID(), occurrence: OccurrenceTime(instant: Date(timeIntervalSince1970: 1_793_511_000), timeZone: .gmt),
            stoolType: 4, amount: .small, effort: .easy, note: note
        )
    }
}

private struct SnapshotFixture: Codable, Equatable {
    let version: Int
    let entries: [DiaryEntry]
}
