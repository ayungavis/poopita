import Foundation
import Security

protocol SecretStore: Sendable {
    func read(key: String) async throws -> Data?
    func write(_ value: Data, key: String) async throws
}

actor KeychainSecretStore: SecretStore {
    private let service: String

    init(service: String = "com.ayungavis.Poopita.secrets") {
        self.service = service
    }

    func read(key: String) throws -> Data? {
        var query = identity(key)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        var result: CFTypeRef?
        switch SecItemCopyMatching(query as CFDictionary, &result) {
        case errSecSuccess:
            guard let data = result as? Data else { throw AppError.storageRead }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw AppError.storageRead
        }
    }

    func write(_ value: Data, key: String) throws {
        var item = identity(key)
        item[kSecValueData] = value
        item[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        item[kSecAttrSynchronizable] = false
        switch SecItemAdd(item as CFDictionary, nil) {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            let status = SecItemUpdate(identity(key) as CFDictionary, [kSecValueData: value] as CFDictionary)
            guard status == errSecSuccess else { throw AppError.storageWrite }
        default:
            throw AppError.storageWrite
        }
    }

    private func identity(_ key: String) -> [CFString: Any] {
        [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: key]
    }
}
