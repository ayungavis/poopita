import Foundation

@MainActor
protocol BackupRepository {
    func lastBackupDate() -> Date?
    func markBackedUp(at date: Date) throws
    func storedKey() async throws -> RecoveryKey?
    func saveKey(_ key: RecoveryKey) async throws
    func makeBackup(createdAt: Date, key: RecoveryKey) async throws -> Data
    func open(_ file: Data, key: RecoveryKey) async throws -> DiaryBackup
    func preview(_ backup: DiaryBackup) throws -> DiaryMerge
    func restore(_ backup: DiaryBackup) throws -> DiaryMerge
}

@MainActor
final class LocalBackupRepository: BackupRepository {
    static let lastBackupKey = "backup.lastCreatedAt"
    static let recoveryKeyAccount = "backup.recoveryKey"
    private let diary: any DiaryRepository
    private let secrets: any SecretStore
    private let store: any ValueStore

    init(diary: any DiaryRepository, secrets: any SecretStore, store: any ValueStore) {
        self.diary = diary
        self.secrets = secrets
        self.store = store
    }

    func lastBackupDate() -> Date? {
        do {
            return try store.read(Date.self, key: Self.lastBackupKey)
        } catch {
            Log.report(error, context: Log.Context(operation: "backup.lastDate"))
            return nil
        }
    }

    func markBackedUp(at date: Date) throws {
        try store.write(date, key: Self.lastBackupKey)
    }

    func storedKey() async throws -> RecoveryKey? {
        guard let data = try await secrets.read(key: Self.recoveryKeyAccount) else { return nil }
        guard let key = RecoveryKey(data: data) else { throw AppError.invalidStoredData }
        return key
    }

    func saveKey(_ key: RecoveryKey) async throws {
        try await secrets.write(key.data, key: Self.recoveryKeyAccount)
    }

    func makeBackup(createdAt: Date, key: RecoveryKey) async throws -> Data {
        let backup = try DiaryBackup(createdAt: createdAt, entries: diary.entries(), checkIns: diary.checkIns())
        return try await Self.seal(backup, key: key)
    }

    func open(_ file: Data, key: RecoveryKey) async throws -> DiaryBackup {
        try await Self.open(file, key: key)
    }

    func preview(_ backup: DiaryBackup) throws -> DiaryMerge {
        try DiaryMerge(entries: diary.entries(), checkIns: diary.checkIns(), backup: backup)
    }

    func restore(_ backup: DiaryBackup) throws -> DiaryMerge {
        let merge = try preview(backup)
        try diary.replaceAll(entries: merge.entries, checkIns: merge.checkIns)
        return merge
    }

    @concurrent
    private nonisolated static func seal(_ backup: DiaryBackup, key: RecoveryKey) async throws -> Data {
        try DiaryBackupCodec.seal(backup, with: key)
    }

    @concurrent
    private nonisolated static func open(_ file: Data, key: RecoveryKey) async throws -> DiaryBackup {
        let backup = try DiaryBackupCodec.open(file, with: key)
        do {
            try DiaryIntegrity.check(entries: backup.entries, checkIns: backup.checkIns)
        } catch {
            throw AppError.backupUnreadable
        }
        return backup
    }
}
