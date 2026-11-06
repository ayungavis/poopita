import Foundation
@testable import PoopitaKit
import Testing

actor MemoryCloudBackupService: CloudBackupService {
    private(set) var file: Data?
    private(set) var writes = 0
    private let available: Bool
    private var modified: Date?

    init(available: Bool = true) {
        self.available = available
    }

    func isAvailable() -> Bool {
        available
    }

    func latestDate() -> Date? {
        modified
    }

    func write(_ file: Data) throws {
        guard available else { throw AppError.cloudUnavailable }
        self.file = file
        writes += 1
        modified = Date(timeIntervalSince1970: 1_793_000_000)
    }

    func read() throws -> Data {
        guard let file else { throw AppError.backupUnreadable }
        return file
    }
}

struct AutomaticBackupRuleTests {
    private let now = Date(timeIntervalSince1970: 1_793_000_000)

    @Test func theFirstBackupAlwaysRuns() {
        #expect(LocalBackupRepository.needsAutomaticBackup(lastBackup: nil, lastFingerprint: nil, fingerprint: "a", now: now))
    }

    @Test func anUnchangedDiaryIsNeverUploadedAgain() {
        let longAgo = now.addingTimeInterval(-30 * 86400)
        #expect(!LocalBackupRepository.needsAutomaticBackup(
            lastBackup: longAgo, lastFingerprint: "a", fingerprint: "a", now: now
        ))
    }

    @Test func aChangedDiaryWaitsUntilADayHasPassed() {
        #expect(!LocalBackupRepository.needsAutomaticBackup(
            lastBackup: now.addingTimeInterval(-3600), lastFingerprint: "a", fingerprint: "b", now: now
        ))
        #expect(LocalBackupRepository.needsAutomaticBackup(
            lastBackup: now.addingTimeInterval(-86400), lastFingerprint: "a", fingerprint: "b", now: now
        ))
    }
}

@MainActor
struct AutomaticBackupTests {
    private let clock = Date(timeIntervalSince1970: 1_793_000_000)

    @Test func nothingIsUploadedUntilAutomaticBackupIsOn() async throws {
        let repositories = try BackupFixtures.repository()
        try await repositories.backup.saveKey(RecoveryKey.generate())
        #expect(try await repositories.backup.backUpToCloudIfNeeded(now: clock) == false)
        #expect(await repositories.cloud.writes == 0)
    }

    @Test func onlyAChangedDiaryIsUploadedAgainAfterADay() async throws {
        let repositories = try BackupFixtures.repository()
        let key = RecoveryKey.generate()
        try await repositories.backup.saveKey(key)
        try repositories.backup.setAutomatic(true)
        try repositories.diary.save(BackupFixtures.entry(at: "2026-11-02T08:00:00Z"))

        #expect(try await repositories.backup.backUpToCloudIfNeeded(now: clock))
        #expect(try await repositories.backup.backUpToCloudIfNeeded(now: clock.addingTimeInterval(2 * 86400)) == false)

        try repositories.diary.save(BackupFixtures.entry(at: "2026-11-03T08:00:00Z"))
        #expect(try await repositories.backup.backUpToCloudIfNeeded(now: clock.addingTimeInterval(3600)) == false)
        #expect(try await repositories.backup.backUpToCloudIfNeeded(now: clock.addingTimeInterval(86400)))
        #expect(await repositories.cloud.writes == 2)

        let uploaded = try #require(await repositories.cloud.file)
        #expect(try await repositories.backup.open(uploaded, key: key).entries.count == 2)
    }

    @Test func turningOnWithoutICloudShowsAnErrorAndStaysOff() async throws {
        let repositories = try BackupFixtures.repository(cloud: MemoryCloudBackupService(available: false))
        let model = BackupModel(
            repository: repositories.backup, undoModel: UndoModel(repository: repositories.diary), now: { clock }
        )
        await model.setAutomatic(true)
        #expect(model.errorMessage == AppError.cloudUnavailable.userMessage)
        #expect(model.keySetup == nil)
        #expect(repositories.backup.isAutomatic() == false)
    }

    @Test func turningOnFirstSavesAKeyThenUploadsInsteadOfExporting() async throws {
        let repositories = try BackupFixtures.repository()
        let model = BackupModel(
            repository: repositories.backup, undoModel: UndoModel(repository: repositories.diary), now: { clock }
        )
        await model.setAutomatic(true)
        let setup = try #require(model.keySetup)
        #expect(repositories.backup.isAutomatic() == false)

        try await model.confirmNewKey(typed: #require(setup.groups.last))
        await model.keySetupDismissed()
        #expect(model.exportFile == nil)
        #expect(repositories.backup.isAutomatic())
        #expect(model.state.isAutomatic)
        #expect(await repositories.cloud.writes == 1)

        await model.setAutomatic(false)
        #expect(repositories.backup.isAutomatic() == false)
    }

    @Test func theICloudBackupRestoresOnANewPhone() async throws {
        let cloud = MemoryCloudBackupService()
        let source = try BackupFixtures.repository(cloud: cloud)
        let key = RecoveryKey.generate()
        try source.diary.save(BackupFixtures.entry(at: "2026-11-02T08:00:00Z"))
        try await source.backup.backUpToCloud(createdAt: clock, key: key)

        let target = try BackupFixtures.repository(cloud: cloud)
        let model = BackupModel(
            repository: target.backup, undoModel: UndoModel(repository: target.diary), now: { clock }
        )
        await model.refresh()
        #expect(model.state.cloudBackup != nil)

        await model.restoreFromCloud()
        #expect(model.restore?.step == .enterKey(errorMessage: nil))
        await model.submitKey(key.groups.joined(separator: " "))
        #expect(model.confirmRestore())
        #expect(try target.diary.entries().count == 1)
    }
}
