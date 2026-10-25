import Darwin
import Foundation
import SwiftData

extension Bundle {
    static var module: Bundle {
        .main
    }
}

@main
struct StorageSmoke {
    @MainActor
    static func main() {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "poopita-storage-smoke-" + UUID().uuidString)
        let result = Result { try roundTrip(directory: directory) }
        do {
            if FileManager.default.fileExists(atPath: directory.path(percentEncoded: false)) {
                try FileManager.default.removeItem(at: directory)
            }
            try result.get()
            print("PASS: Simulator diary opens, commits, and reopens")
        } catch {
            FileHandle.standardError.write(Data("FAIL: Simulator diary storage: \(error)\n".utf8))
            exit(EXIT_FAILURE)
        }
    }

    @MainActor
    private static func roundTrip(directory: URL) throws {
        do {
            let store = try SwiftDataValueStore(directory: directory)
            try store.write("fictional entry", key: "smoke")
        }
        let reopened = try SwiftDataValueStore(directory: directory)
        guard try reopened.read(String.self, key: "smoke") == "fictional entry" else {
            throw AppError.invalidStoredData
        }
        let items = try [directory] + FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.isExcludedFromBackupKey]
        )
        for item in items {
            guard try item.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true else {
                throw AppError.storageUnavailable
            }
        }
    }
}
