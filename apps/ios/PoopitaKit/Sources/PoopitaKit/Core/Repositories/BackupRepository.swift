import CryptoKit
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
    func isAutomatic() -> Bool
    func setAutomatic(_ isOn: Bool) throws
    func isCloudAvailable() async -> Bool
    func cloudBackupDate() async -> Date?
    func backUpToCloud(createdAt: Date, key: RecoveryKey) async throws
    @discardableResult
    func backUpToCloudIfNeeded(now: Date) async throws -> Bool
    func readCloudBackup() async throws -> Data
}

@MainActor
final class LocalBackupRepository: BackupRepository {
    static let lastBackupKey = "backup.lastCreatedAt"
    static let recoveryKeyAccount = "backup.recoveryKey"
    static let automaticKey = "backup.automatic"
    static let cloudFingerprintKey = "backup.cloudFingerprint"
    static let cloudDateKey = "backup.cloudCreatedAt"
    nonisolated static let automaticInterval: TimeInterval = 24 * 60 * 60
    private let diary: any DiaryRepository
    private let secrets: any SecretStore
    private let store: any ValueStore
    private let cloud: any CloudBackupService

    init(diary: any DiaryRepository, secrets: any SecretStore, store: any ValueStore, cloud: any CloudBackupService) {
        self.diary = diary
        self.secrets = secrets
        self.store = store
        self.cloud = cloud
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

    func isAutomatic() -> Bool {
        (try? store.read(Bool.self, key: Self.automaticKey)) ?? false
    }

    func setAutomatic(_ isOn: Bool) throws {
        try store.write(isOn, key: Self.automaticKey)
    }

    func isCloudAvailable() async -> Bool {
        await cloud.isAvailable()
    }

    func cloudBackupDate() async -> Date? {
        await cloud.latestDate()
    }

    func backUpToCloud(createdAt: Date, key: RecoveryKey) async throws {
        let backup = try DiaryBackup(createdAt: createdAt, entries: diary.entries(), checkIns: diary.checkIns())
        let sealed = try await Self.sealWithFingerprint(backup, key: key)
        try await cloud.write(sealed.file)
        try store.write(sealed.fingerprint, key: Self.cloudFingerprintKey)
        try store.write(createdAt, key: Self.cloudDateKey)
        try markBackedUp(at: createdAt)
    }

    @discardableResult
    func backUpToCloudIfNeeded(now: Date) async throws -> Bool {
        guard isAutomatic(), let key = try await storedKey() else { return false }
        let entries = try diary.entries()
        let checkIns = try diary.checkIns()
        let fingerprint = try await Self.fingerprint(entries: entries, checkIns: checkIns)
        let lastFingerprint = try? store.read(String.self, key: Self.cloudFingerprintKey)
        guard Self.needsAutomaticBackup(
            lastBackup: try? store.read(Date.self, key: Self.cloudDateKey), lastFingerprint: lastFingerprint,
            fingerprint: fingerprint, now: now
        ) else { return false }
        try await backUpToCloud(createdAt: now, key: key)
        return true
    }

    func readCloudBackup() async throws -> Data {
        try await cloud.read()
    }

    nonisolated static func needsAutomaticBackup(
        lastBackup: Date?, lastFingerprint: String?, fingerprint: String, now: Date
    ) -> Bool {
        guard fingerprint != lastFingerprint else { return false }
        guard let lastBackup else { return true }
        return now.timeIntervalSince(lastBackup) >= automaticInterval
    }

    @concurrent
    private nonisolated static func fingerprint(entries: [DiaryEntry], checkIns: [NoPoopCheckIn]) async throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let payload = try encoder.encode(DiaryBackup(createdAt: .distantPast, entries: entries, checkIns: checkIns))
        return SHA256.hash(data: payload).map { String(format: "%02x", $0) }.joined()
    }

    @concurrent
    private nonisolated static func sealWithFingerprint(
        _ backup: DiaryBackup, key: RecoveryKey
    ) async throws -> (file: Data, fingerprint: String) {
        let file = try DiaryBackupCodec.seal(backup, with: key)
        let fingerprint = try await fingerprint(entries: backup.entries, checkIns: backup.checkIns)
        return (file, fingerprint)
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
