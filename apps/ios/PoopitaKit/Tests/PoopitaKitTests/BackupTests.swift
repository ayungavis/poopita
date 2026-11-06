import Foundation
@testable import PoopitaKit
import Testing

actor MemorySecretStore: SecretStore {
    private var values: [String: Data] = [:]

    func read(key: String) -> Data? {
        values[key]
    }

    func write(_ value: Data, key: String) {
        values[key] = value
    }
}

struct RecoveryKeyTests {
    @Test func aGeneratedKeyReadsBackFromItsGroups() {
        let key = RecoveryKey.generate()
        #expect(key.groups.count == 13)
        #expect(key.groups.allSatisfy { $0.count == 4 })
        #expect(RecoveryKey(text: key.groups.joined(separator: " ")) == key)
    }

    @Test func typingIsForgivingAboutCaseSeparatorsAndLookAlikes() throws {
        let key = try #require(RecoveryKey(data: Data(repeating: 0, count: 32)))
        let typed = key.groups.joined(separator: "-").lowercased().replacing("0", with: "o")
        #expect(RecoveryKey(text: typed) == key)
    }

    @Test(arguments: ["", "ABCD", "U" + String(repeating: "0", count: 51), String(repeating: "0", count: 51) + "1"])
    func malformedTextIsNotAKey(text: String) {
        #expect(RecoveryKey(text: text) == nil)
    }
}

struct DiaryBackupCodecTests {
    private let key = RecoveryKey.generate()

    @Test func aSealedBackupOpensWithTheSameKey() throws {
        let backup = try BackupFixtures.backup()
        let file = try DiaryBackupCodec.seal(backup, with: key)
        #expect(try DiaryBackupCodec.open(file, with: key) == backup)
    }

    @Test func anotherKeyIsReportedAsTheWrongKey() throws {
        let file = try DiaryBackupCodec.seal(BackupFixtures.backup(), with: key)
        #expect(throws: AppError.backupKeyMismatch) { try DiaryBackupCodec.open(file, with: RecoveryKey.generate()) }
    }

    @Test func aDamagedFileIsUnreadable() throws {
        var file = try DiaryBackupCodec.seal(BackupFixtures.backup(), with: key)
        file[file.index(file.endIndex, offsetBy: -20)] ^= 0x01
        #expect(throws: AppError.backupUnreadable) { try DiaryBackupCodec.open(file, with: key) }
        #expect(throws: AppError.backupUnreadable) { try DiaryBackupCodec.open(Data("not a backup".utf8), with: key) }
    }

    @Test func aNewerFormatAsksForAnUpdate() throws {
        var file = try DiaryBackupCodec.seal(BackupFixtures.backup(), with: key)
        file[file.startIndex + 4] = DiaryBackupCodec.formatVersion + 1
        #expect(throws: AppError.backupFromNewerVersion) { try DiaryBackupCodec.open(file, with: key) }
    }
}

struct DiaryMergeTests {
    @Test func anEmptyPhoneGetsTheWholeBackup() throws {
        let backup = try BackupFixtures.backup()
        let merge = DiaryMerge(entries: [], checkIns: [], backup: backup)
        #expect(merge.entries == backup.entries)
        #expect(merge.checkIns == backup.checkIns)
        #expect(merge.addedEntries == 1)
        #expect(merge.addedCheckIns == 1)
        #expect(merge.entriesAlreadyHere == 0)
    }

    @Test func theCopyOnThePhoneWinsForTheSameLog() throws {
        let backup = try BackupFixtures.backup()
        let backedUp = try #require(backup.entries.first)
        let edited = DiaryEntry(
            id: backedUp.id, occurrence: backedUp.occurrence, stoolType: 6, amount: nil, effort: nil, note: "edited"
        )
        let merge = DiaryMerge(entries: [edited], checkIns: [], backup: backup)
        #expect(merge.entries == [edited])
        #expect(merge.addedEntries == 0)
        #expect(merge.entriesAlreadyHere == 1)
    }

    @Test func aLogOnADayReplacesThatDaysCheckInFromEitherSide() throws {
        let backup = try BackupFixtures.backup()
        let backedUpCheckIn = try #require(backup.checkIns.first)
        let phoneEntry = try BackupFixtures.entry(at: "2026-11-03T08:00:00Z")
        let phoneCheckIn = try BackupFixtures.checkIn(day: "2026-11-02T12:00:00Z", reportedAt: "2026-11-04T09:00:00Z")
        let merge = DiaryMerge(entries: [phoneEntry], checkIns: [phoneCheckIn], backup: backup)
        #expect(!merge.checkIns.contains(backedUpCheckIn))
        #expect(!merge.checkIns.contains(phoneCheckIn))
        #expect(merge.addedCheckIns == 0)
        try DiaryIntegrity.check(entries: merge.entries, checkIns: merge.checkIns)
    }

    @Test func thePhonesCheckInWinsForTheSameDay() throws {
        let backup = try BackupFixtures.backup()
        let phoneCheckIn = try BackupFixtures.checkIn(day: "2026-11-03T12:00:00Z", reportedAt: "2026-11-05T07:00:00Z")
        let merge = DiaryMerge(entries: [], checkIns: [phoneCheckIn], backup: backup)
        #expect(merge.checkIns.filter { $0.day == phoneCheckIn.day } == [phoneCheckIn])
        #expect(merge.addedCheckIns == 0)
    }
}

@MainActor
struct BackupRepositoryTests {
    @Test func aBackupRestoresIntoAnotherPhoneAndCanBeUndone() async throws {
        let source = try BackupFixtures.repository()
        let backup = try BackupFixtures.backup()
        try source.diary.replaceAll(entries: backup.entries, checkIns: backup.checkIns)
        let key = RecoveryKey.generate()
        let file = try await source.backup.makeBackup(createdAt: backup.createdAt, key: key)

        let target = try BackupFixtures.repository()
        let existing = try BackupFixtures.entry(at: "2026-11-04T19:30:00Z")
        try target.diary.save(existing)
        let opened = try await target.backup.open(file, key: key)
        #expect(try target.backup.preview(opened).addedEntries == 1)
        #expect(try target.diary.entries().count == 1)

        let merge = try target.backup.restore(opened)
        #expect(merge.addedEntries == 1)
        #expect(try Set(target.diary.entries().map(\.id)) == Set(backup.entries.map(\.id) + [existing.id]))
        #expect(try target.diary.checkIns() == backup.checkIns)

        try target.diary.undo()
        #expect(try target.diary.entries() == [existing])
        #expect(try target.diary.checkIns().isEmpty)
    }

    @Test func aBackupThatBreaksTheDiaryRulesWritesNothing() async throws {
        let target = try BackupFixtures.repository()
        let entry = try BackupFixtures.entry(at: "2026-11-02T08:00:00Z")
        let broken = DiaryBackup(createdAt: .now, entries: [entry, entry], checkIns: [])
        let key = RecoveryKey.generate()
        let file = try DiaryBackupCodec.seal(broken, with: key)
        await #expect(throws: AppError.backupUnreadable) { try await target.backup.open(file, key: key) }
        #expect(try target.diary.entries().isEmpty)
    }

    @Test func theRecoveryKeyAndLastBackupDateAreRemembered() async throws {
        let target = try BackupFixtures.repository()
        #expect(try await target.backup.storedKey() == nil)
        #expect(target.backup.lastBackupDate() == nil)
        let key = RecoveryKey.generate()
        let date = Date(timeIntervalSince1970: 1_793_000_000)
        try await target.backup.saveKey(key)
        try target.backup.markBackedUp(at: date)
        #expect(try await target.backup.storedKey() == key)
        #expect(target.backup.lastBackupDate() == date)
    }
}

@MainActor
enum BackupFixtures {
    struct Repositories {
        let diary: LocalDiaryRepository
        let backup: LocalBackupRepository
    }

    static func repository() throws -> Repositories {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let diary = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let suite = "BackupTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let backup = LocalBackupRepository(
            diary: diary, secrets: MemorySecretStore(), store: UserDefaultsValueStore(defaults: defaults)
        )
        return Repositories(diary: diary, backup: backup)
    }

    nonisolated static func backup() throws -> DiaryBackup {
        try DiaryBackup(
            createdAt: date("2026-11-05T10:00:00Z"),
            entries: [entry(at: "2026-11-02T08:00:00Z")],
            checkIns: [checkIn(day: "2026-11-03T12:00:00Z", reportedAt: "2026-11-04T09:00:00Z")]
        )
    }

    nonisolated static func entry(at value: String) throws -> DiaryEntry {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        return try DiaryEntry(
            id: UUID(), occurrence: OccurrenceTime(instant: date(value), timeZone: zone), stoolType: 4,
            amount: .medium, effort: .easy, blood: DiaryEntry.Blood.none, note: "felt fine"
        )
    }

    nonisolated static func checkIn(day: String, reportedAt: String) throws -> NoPoopCheckIn {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        return try NoPoopCheckIn(
            day: DiaryDay(date: date(day), timeZone: zone),
            reportedAt: OccurrenceTime(instant: date(reportedAt), timeZone: zone),
            coverage: .completed
        )
    }

    private nonisolated static func date(_ value: String) throws -> Date {
        guard let date = ISO8601DateFormatter().date(from: value) else { throw AppError.invalidOccurrence }
        return date
    }
}

@MainActor
struct BackupModelTests {
    private let clock = Date(timeIntervalSince1970: 1_793_000_000)

    @Test func theFirstBackupWaitsUntilTheKeyIsConfirmed() async throws {
        let repositories = try BackupFixtures.repository()
        let model = BackupModel(
            repository: repositories.backup, undoModel: UndoModel(repository: repositories.diary), now: { clock }
        )

        await model.createBackup()
        let setup = try #require(model.keySetup)
        #expect(model.exportFile == nil)
        #expect(try await repositories.backup.storedKey() == nil)

        await model.confirmNewKey(typed: "WRONG")
        #expect(model.keySetup?.errorMessage != nil)
        #expect(model.exportFile == nil)

        try await model.confirmNewKey(typed: #require(setup.groups.last).lowercased())
        #expect(model.keySetup == nil)
        #expect(try await repositories.backup.storedKey() != nil)
        #expect(model.exportFile == nil)

        await model.keySetupDismissed()
        let file = try #require(model.exportFile)
        #expect(file.fileName.hasSuffix(".poopitabackup"))

        model.finishExport(saved: true)
        #expect(repositories.backup.lastBackupDate() == clock)
    }

    @Test func aCancelledExportIsNotRecordedAsABackup() async throws {
        let repositories = try BackupFixtures.repository()
        try await repositories.backup.saveKey(RecoveryKey.generate())
        let model = BackupModel(
            repository: repositories.backup, undoModel: UndoModel(repository: repositories.diary), now: { clock }
        )
        await model.createBackup()
        #expect(model.keySetup == nil)
        #expect(model.exportFile != nil)
        model.finishExport(saved: false)
        #expect(model.exportFile == nil)
        #expect(repositories.backup.lastBackupDate() == nil)
    }

    @Test func restoringWithTheStoredKeyPreviewsThenMergesAndReloads() async throws {
        let source = try BackupFixtures.repository()
        let backup = try BackupFixtures.backup()
        try source.diary.replaceAll(entries: backup.entries, checkIns: backup.checkIns)
        let key = RecoveryKey.generate()
        let url = try await write(source.backup.makeBackup(createdAt: backup.createdAt, key: key))

        let target = try BackupFixtures.repository()
        try await target.backup.saveKey(key)
        let undo = UndoModel(repository: target.diary)
        let model = BackupModel(repository: target.backup, undoModel: undo, now: { clock })

        await model.importFile(.success(url))
        guard case let .preview(preview) = try #require(model.restore).step else {
            Issue.record("Expected a preview")
            return
        }
        #expect(preview.logsToAdd == 1.formatted())
        #expect(try target.diary.entries().isEmpty)

        #expect(model.confirmRestore())
        #expect(model.restore == nil)
        #expect(try target.diary.entries() == backup.entries)
        #expect(undo.revision == 1)
        #expect(undo.toast?.canUndo == true)
    }

    @Test func anotherKeyIsAskedForThenSavedForTheNextBackup() async throws {
        let source = try BackupFixtures.repository()
        let key = RecoveryKey.generate()
        let url = try await write(source.backup.makeBackup(createdAt: clock, key: key))

        let target = try BackupFixtures.repository()
        let model = BackupModel(
            repository: target.backup, undoModel: UndoModel(repository: target.diary), now: { clock }
        )
        await model.importFile(.success(url))
        #expect(model.restore?.step == .enterKey(errorMessage: nil))

        await model.submitKey("not a key")
        #expect(model.restore?.step == .enterKey(errorMessage: AppError.invalidRecoveryKey.userMessage))

        await model.submitKey(RecoveryKey.generate().groups.joined(separator: " "))
        #expect(model.restore?.step == .enterKey(errorMessage: AppError.backupKeyMismatch.userMessage))

        await model.submitKey(key.groups.joined(separator: "-"))
        guard case .preview = try #require(model.restore).step else {
            Issue.record("Expected a preview")
            return
        }
        #expect(try await target.backup.storedKey() == key)
    }

    @Test func aFileThatIsNotABackupShowsAnError() async throws {
        let target = try BackupFixtures.repository()
        try await target.backup.saveKey(RecoveryKey.generate())
        let model = BackupModel(
            repository: target.backup, undoModel: UndoModel(repository: target.diary), now: { clock }
        )
        try await model.importFile(.success(write(Data("hello".utf8))))
        #expect(model.restore == nil)
        #expect(model.errorMessage == AppError.backupUnreadable.userMessage)
    }

    @Test func theStatusNamesTheLastBackupDate() {
        #expect(BackupModel.status(lastBackup: nil) == String(localized: "settings.backup.never", bundle: .module))
        #expect(BackupModel.status(lastBackup: clock).contains(clock.formatted(.dateTime.year())))
    }

    private func write(_ data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).poopitabackup")
        try data.write(to: url)
        return url
    }
}
