import Foundation

@MainActor
final class UserDefaultsValueStore: ValueStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func read<Value: Codable>(_ type: Value.Type, key: String) throws -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw AppError.invalidStoredData
        }
    }

    func write(_ value: some Codable, key: String) throws {
        do {
            try defaults.set(JSONEncoder().encode(value), forKey: key)
        } catch {
            throw AppError.storageWrite
        }
    }
}
