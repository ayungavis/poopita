import Foundation
import Observation

@MainActor
@Observable
final class BackupModel {
    private(set) var state = BackupModel.viewData(
        lastBackup: nil, hasRecoveryKey: false, isAutomatic: false, isCloudAvailable: true, cloudBackup: nil
    )
    private(set) var keySetup: RecoveryKeySetupViewData?
    private(set) var keyDisplay: RecoveryKeyDisplayViewData?
    private(set) var exportFile: BackupFileViewData?
    private(set) var restore: RestoreViewData?
    private(set) var errorMessage: String?
    private(set) var isWorking = false
    private let repository: any BackupRepository
    private let undoModel: UndoModel
    private let now: () -> Date
    private var pendingKey: RecoveryKey?
    private var confirmedKey: RecoveryKey?
    private var isEnablingAutomatic = false
    private var openedFile: Data?
    private var openedBackup: DiaryBackup?

    init(repository: any BackupRepository, undoModel: UndoModel, now: @escaping () -> Date) {
        self.repository = repository
        self.undoModel = undoModel
        self.now = now
    }

    func refresh() async {
        let hasKey = await (try? repository.storedKey()) != nil
        let isCloudAvailable = await repository.isCloudAvailable()
        let cloudBackup = isCloudAvailable ? await repository.cloudBackupDate() : nil
        state = Self.viewData(
            lastBackup: repository.lastBackupDate(), hasRecoveryKey: hasKey, isAutomatic: repository.isAutomatic(),
            isCloudAvailable: isCloudAvailable, cloudBackup: cloudBackup
        )
    }

    func setAutomatic(_ isOn: Bool) async {
        guard isOn else {
            do {
                try repository.setAutomatic(false)
            } catch {
                show(error, operation: "backup.automatic")
            }
            await refresh()
            return
        }
        await perform {
            guard await self.repository.isCloudAvailable() else { throw AppError.cloudUnavailable }
            if let key = try await self.repository.storedKey() {
                try await self.enableAutomatic(with: key)
            } else {
                let key = RecoveryKey.generate()
                self.pendingKey = key
                self.isEnablingAutomatic = true
                self.keySetup = Self.setupViewData(key: key, errorMessage: nil)
            }
        }
    }

    func backUpIfNeeded() async {
        guard !isWorking else { return }
        do {
            if try await repository.backUpToCloudIfNeeded(now: now()) {
                await refresh()
            }
        } catch {
            Log.report(error, context: Log.Context(operation: "backup.automatic"))
        }
    }

    func createBackup() async {
        await perform {
            if let key = try await self.repository.storedKey() {
                try await self.prepareExport(with: key)
            } else {
                let key = RecoveryKey.generate()
                self.pendingKey = key
                self.keySetup = Self.setupViewData(key: key, errorMessage: nil)
            }
        }
    }

    func confirmNewKey(typed: String) async {
        guard let key = pendingKey else { return }
        guard Self.confirms(typed, key: key) else {
            keySetup = Self.setupViewData(
                key: key, errorMessage: String(localized: "backup.key.mismatch", bundle: .module)
            )
            return
        }
        await perform {
            try await self.repository.saveKey(key)
            self.pendingKey = nil
            self.confirmedKey = key
            self.keySetup = nil
            await self.refresh()
        }
    }

    func keySetupDismissed() async {
        guard let key = confirmedKey else { return }
        confirmedKey = nil
        let enablesAutomatic = isEnablingAutomatic
        isEnablingAutomatic = false
        await perform {
            if enablesAutomatic {
                try await self.enableAutomatic(with: key)
            } else {
                try await self.prepareExport(with: key)
            }
        }
    }

    func cancelKeySetup() {
        pendingKey = nil
        keySetup = nil
        if confirmedKey == nil {
            isEnablingAutomatic = false
        }
    }

    func finishExport(saved: Bool) {
        exportFile = nil
        guard saved else { return }
        do {
            try repository.markBackedUp(at: now())
            undoModel.record(String(localized: "backup.saved", bundle: .module), undoable: false)
            Task { await refresh() }
        } catch {
            show(error, operation: "backup.mark")
        }
    }

    func exportFailed(_ error: any Error) {
        exportFile = nil
        show(error, operation: "backup.export")
    }

    func showKey() async {
        await perform {
            guard let key = try await self.repository.storedKey() else { return }
            self.keyDisplay = RecoveryKeyDisplayViewData(id: UUID(), groups: key.groups, shareText: Self.shareText(key))
        }
    }

    func hideKey() {
        keyDisplay = nil
    }

    func dismissError() {
        errorMessage = nil
    }

    private func enableAutomatic(with key: RecoveryKey) async throws {
        try repository.setAutomatic(true)
        do {
            try await repository.backUpToCloud(createdAt: now(), key: key)
        } catch {
            try? repository.setAutomatic(false)
            await refresh()
            throw error
        }
        undoModel.record(String(localized: "backup.cloud.saved", bundle: .module), undoable: false)
        await refresh()
    }

    private func prepareExport(with key: RecoveryKey) async throws {
        let date = now()
        let file = try await repository.makeBackup(createdAt: date, key: key)
        exportFile = BackupFileViewData(data: file, fileName: Self.fileName(date: date))
    }

    private func perform(_ work: @MainActor () async throws -> Void) async {
        guard !isWorking else { return }
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            try await work()
        } catch {
            show(error, operation: "backup")
        }
    }

    private func show(_ error: any Error, operation: String) {
        Log.report(error, context: Log.Context(operation: operation))
        errorMessage = AppError(wrapping: error).userMessage
    }

    @concurrent
    private nonisolated static func read(_ url: URL) async throws -> Data {
        let isScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            return try Data(contentsOf: url, options: .mappedIfSafe)
        } catch {
            throw AppError.backupUnreadable
        }
    }
}

extension BackupModel {
    func importFile(_ result: Result<URL, any Error>) async {
        guard case let .success(url) = result else {
            if case let .failure(error) = result {
                show(error, operation: "backup.import")
            }
            return
        }
        await perform {
            try await self.openFile(Self.read(url))
        }
    }

    func restoreFromCloud() async {
        await perform {
            try await self.openFile(self.repository.readCloudBackup())
        }
    }

    func submitKey(_ text: String) async {
        guard let file = openedFile, let current = restore else { return }
        guard let key = RecoveryKey(text: text) else {
            restore = RestoreViewData(
                id: current.id, step: .enterKey(errorMessage: AppError.invalidRecoveryKey.userMessage)
            )
            return
        }
        await perform {
            do {
                try await self.open(file, key: key)
                if try await self.repository.storedKey() == nil {
                    try await self.repository.saveKey(key)
                    await self.refresh()
                }
            } catch let error as AppError where error == .backupKeyMismatch || error == .backupFromNewerVersion {
                self.restore = RestoreViewData(id: current.id, step: .enterKey(errorMessage: error.userMessage))
            }
        }
    }

    @discardableResult
    func confirmRestore() -> Bool {
        guard let backup = openedBackup else { return false }
        do {
            try repository.restore(backup)
            undoModel.record(String(localized: "backup.restored", bundle: .module), reloads: true)
            cancelRestore()
            return true
        } catch {
            Log.report(error, context: Log.Context(operation: "backup.restore"))
            if let current = restore, case let .preview(preview) = current.step {
                restore = RestoreViewData(id: current.id, step: .preview(RestorePreviewViewData(
                    createdAt: preview.createdAt, logsToAdd: preview.logsToAdd, checkInsToAdd: preview.checkInsToAdd,
                    alreadyHere: preview.alreadyHere, errorMessage: AppError(wrapping: error).userMessage
                )))
            }
            return false
        }
    }

    func cancelRestore() {
        restore = nil
        openedFile = nil
        openedBackup = nil
    }

    private func openFile(_ file: Data) async throws {
        openedFile = file
        guard let key = try await repository.storedKey() else {
            restore = RestoreViewData(id: UUID(), step: .enterKey(errorMessage: nil))
            return
        }
        do {
            try await open(file, key: key)
        } catch AppError.backupKeyMismatch {
            restore = RestoreViewData(id: UUID(), step: .enterKey(errorMessage: nil))
        }
    }

    private func open(_ file: Data, key: RecoveryKey) async throws {
        let backup = try await repository.open(file, key: key)
        let merge = try repository.preview(backup)
        openedBackup = backup
        restore = RestoreViewData(
            id: restore?.id ?? UUID(), step: .preview(Self.previewViewData(backup: backup, merge: merge))
        )
    }
}

extension BackupModel {
    static func viewData(
        lastBackup: Date?, hasRecoveryKey: Bool, isAutomatic: Bool, isCloudAvailable: Bool, cloudBackup: Date?
    ) -> BackupViewData {
        let automaticDetail: String = if isAutomatic, !isCloudAvailable {
            AppError.cloudUnavailable.userMessage
        } else if isAutomatic {
            String(localized: "settings.backup.automatic.on", bundle: .module)
        } else {
            String(localized: "settings.backup.automatic.off", bundle: .module)
        }
        return BackupViewData(
            status: status(lastBackup: lastBackup), hasRecoveryKey: hasRecoveryKey, isAutomatic: isAutomatic,
            automaticDetail: automaticDetail,
            cloudBackup: cloudBackup.map {
                String(
                    localized: "backup.restore.cloud \($0.formatted(.dateTime.day().month(.abbreviated).year()))",
                    bundle: .module
                )
            }
        )
    }

    static func status(lastBackup: Date?) -> String {
        guard let lastBackup else { return String(localized: "settings.backup.never", bundle: .module) }
        let date = lastBackup.formatted(.dateTime.day().month(.abbreviated).year())
        return String(localized: "settings.backup.last \(date)", bundle: .module)
    }

    static func setupViewData(key: RecoveryKey, errorMessage: String?) -> RecoveryKeySetupViewData {
        RecoveryKeySetupViewData(
            id: UUID(), groups: key.groups, shareText: shareText(key),
            confirmPrompt: String(localized: "backup.key.confirmPrompt \(key.groups.count)", bundle: .module),
            errorMessage: errorMessage
        )
    }

    static func confirms(_ typed: String, key: RecoveryKey) -> Bool {
        let answer = typed.filter { !$0.isWhitespace }.uppercased()
        return answer == key.groups.last
    }

    static func shareText(_ key: RecoveryKey) -> String {
        String(localized: "backup.key.shareText \(key.groups.joined(separator: " "))", bundle: .module)
    }

    static func previewViewData(backup: DiaryBackup, merge: DiaryMerge) -> RestorePreviewViewData {
        RestorePreviewViewData(
            createdAt: String(
                localized: "backup.restore.from \(backup.createdAt.formatted(date: .abbreviated, time: .shortened))",
                bundle: .module
            ),
            logsToAdd: merge.addedEntries.formatted(), checkInsToAdd: merge.addedCheckIns.formatted(),
            alreadyHere: merge.entriesAlreadyHere.formatted(), errorMessage: nil
        )
    }

    static func fileName(date: Date) -> String {
        "poopita-backup-\(date.formatted(.iso8601.year().month().day())).poopitabackup"
    }
}
