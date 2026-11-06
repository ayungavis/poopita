import CryptoKit
import Foundation

enum DiaryBackupCodec {
    static let formatVersion: UInt8 = 1
    private static let magic = Data("PTBK".utf8)
    private static let fingerprintLength = 8

    static func seal(_ backup: DiaryBackup, with key: RecoveryKey) throws -> Data {
        let header = magic + [formatVersion] + key.fingerprint
        do {
            let payload = try JSONEncoder().encode(backup)
            let box = try AES.GCM.seal(payload, using: key.symmetricKey, authenticating: header)
            guard let combined = box.combined else { throw AppError.unexpected }
            return header + combined
        } catch {
            throw AppError.unexpected
        }
    }

    static func open(_ file: Data, with key: RecoveryKey) throws -> DiaryBackup {
        let headerLength = magic.count + 1 + fingerprintLength
        guard file.count > headerLength, file.prefix(magic.count) == magic else { throw AppError.backupUnreadable }
        let version = file[file.startIndex + magic.count]
        guard version <= formatVersion else { throw AppError.backupFromNewerVersion }
        guard version == formatVersion else { throw AppError.backupUnreadable }
        let header = file.prefix(headerLength)
        guard header.suffix(fingerprintLength) == key.fingerprint else { throw AppError.backupKeyMismatch }
        let payload: Data
        do {
            let box = try AES.GCM.SealedBox(combined: file.dropFirst(headerLength))
            payload = try AES.GCM.open(box, using: key.symmetricKey, authenticating: header)
        } catch {
            throw AppError.backupUnreadable
        }
        do {
            return try JSONDecoder().decode(DiaryBackup.self, from: payload)
        } catch {
            throw AppError.backupUnreadable
        }
    }
}
