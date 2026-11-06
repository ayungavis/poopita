import Foundation
#if canImport(UIKit)
    import UIKit
#endif

protocol CloudBackupService: Sendable {
    func isAvailable() async -> Bool
    func latestDate() async -> Date?
    func write(_ file: Data) async throws
    func read() async throws -> Data
}

final class ICloudDriveBackupService: CloudBackupService {
    static let containerIdentifier = "iCloud.com.ayungavis.Poopita"
    static let fileName = "Poopita Backup.poopitabackup"
    private let queue = DispatchQueue(label: "com.ayungavis.Poopita.cloudBackup", qos: .utility)

    func isAvailable() async -> Bool {
        await run { _ in FileManager.default.ubiquityIdentityToken != nil }
    }

    func latestDate() async -> Date? {
        try? await run { manager in
            let url = try Self.fileURL(manager)
            let values = try url.resourceValues(forKeys: [.contentModificationDateKey, .ubiquitousItemDownloadingStatusKey])
            return values.contentModificationDate
        }
    }

    func write(_ file: Data) async throws {
        #if canImport(UIKit)
            let task = await UIApplication.shared.beginBackgroundTask(withName: "Poopita backup")
        #endif
        defer {
            #if canImport(UIKit)
                Task { @MainActor in UIApplication.shared.endBackgroundTask(task) }
            #endif
        }
        try await run { manager in
            let url = try Self.fileURL(manager)
            try Self.coordinate(writing: url) { try file.write(to: $0, options: .atomic) }
        }
    }

    func read() async throws -> Data {
        try await run { manager in
            let url = try Self.fileURL(manager)
            try? manager.startDownloadingUbiquitousItem(at: url)
            return try Self.coordinate(reading: url) { try Data(contentsOf: $0) }
        }
    }

    private func run<Value: Sendable>(_ work: @escaping @Sendable (FileManager) throws -> Value) async throws -> Value {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                continuation.resume(with: Result { try work(.default) })
            }
        }
    }

    private func run<Value: Sendable>(_ work: @escaping @Sendable (FileManager) -> Value) async -> Value {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: work(.default))
            }
        }
    }

    private static func fileURL(_ manager: FileManager) throws -> URL {
        guard manager.ubiquityIdentityToken != nil,
              let container = manager.url(forUbiquityContainerIdentifier: containerIdentifier)
        else { throw AppError.cloudUnavailable }
        let folder = container.appending(path: "Documents", directoryHint: .isDirectory)
        do {
            try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            throw AppError.cloudUnavailable
        }
        return folder.appending(path: fileName)
    }

    private static func coordinate(writing url: URL, _ write: (URL) throws -> Void) throws {
        var coordinationError: NSError?
        var writeError: (any Error)?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { target in
            do {
                try write(target)
            } catch {
                writeError = error
            }
        }
        guard coordinationError == nil, writeError == nil else { throw AppError.storageWrite }
    }

    private static func coordinate(reading url: URL, _ read: (URL) throws -> Data) throws -> Data {
        var coordinationError: NSError?
        var result: Result<Data, any Error> = .failure(AppError.backupUnreadable)
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { source in
            result = Result { try read(source) }
        }
        guard coordinationError == nil, case let .success(data) = result else { throw AppError.backupUnreadable }
        return data
    }
}
