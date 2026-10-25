import Foundation

public enum ProtectedStorage {
    public static func directory(named name: String) throws -> URL {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        return support.appending(path: "com.ayungavis.Poopita", directoryHint: .isDirectory)
            .appending(path: name, directoryHint: .isDirectory)
    }

    public static func prepare(_ directory: URL) throws {
        guard directory.isFileURL else { throw AppError.storageUnavailable }
        let manager = FileManager.default
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        let items = try [directory] + (manager.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.isSymbolicLinkKey], options: []
        ))
        for item in items {
            guard try item.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true else {
                throw AppError.storageUnavailable
            }
            var excluded = URLResourceValues()
            excluded.isExcludedFromBackup = true
            var target = item
            try target.setResourceValues(excluded)
            guard try target.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true else {
                throw AppError.storageUnavailable
            }
            #if os(iOS) && !targetEnvironment(simulator)
                try manager.setAttributes(
                    [.protectionKey: FileProtectionType.complete],
                    ofItemAtPath: item.path(percentEncoded: false)
                )
                let attributes = try manager.attributesOfItem(atPath: item.path(percentEncoded: false))
                guard attributes[.protectionKey] as? String == FileProtectionType.complete.rawValue else {
                    throw AppError.storageUnavailable
                }
            #endif
        }
    }
}
