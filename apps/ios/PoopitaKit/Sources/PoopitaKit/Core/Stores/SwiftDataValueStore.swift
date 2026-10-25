import Foundation
import SwiftData

@MainActor
protocol ValueStore {
    func read<Value: Codable>(_ type: Value.Type, key: String) throws -> Value?
    func write(_ value: some Codable, key: String) throws
}

@Model
final class StoreValueEntity {
    @Attribute(.unique) var key: String
    var payload: Data

    init(key: String, payload: Data) {
        self.key = key
        self.payload = payload
    }
}

@MainActor
final class SwiftDataValueStore: ValueStore {
    private let container: ModelContainer
    private let directory: URL
    private let commit: (ModelContext) throws -> Void

    convenience init(directory: URL) throws {
        try self.init(directory: directory, commit: { try $0.save() })
    }

    init(directory: URL, commit: @escaping (ModelContext) throws -> Void) throws {
        do {
            try ProtectedStorage.prepare(directory)
            let configuration = ModelConfiguration(
                "LocalValues", schema: Schema([StoreValueEntity.self]),
                url: directory.appending(path: "values.store"), allowsSave: true, cloudKitDatabase: .none
            )
            container = try ModelContainer(for: StoreValueEntity.self, configurations: configuration)
            try ProtectedStorage.prepare(directory)
        } catch {
            throw AppError.storageUnavailable
        }
        self.directory = directory
        self.commit = commit
    }

    func read<Value: Codable>(_ type: Value.Type, key: String) throws -> Value? {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        do {
            guard let entity = try entity(key: key, context: context) else { return nil }
            do {
                return try JSONDecoder().decode(type, from: entity.payload)
            } catch {
                throw AppError.invalidStoredData
            }
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.storageRead
        }
    }

    func write(_ value: some Codable, key: String) throws {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        do {
            let payload = try JSONEncoder().encode(value)
            try ProtectedStorage.prepare(directory)
            if let entity = try entity(key: key, context: context) {
                entity.payload = payload
            } else {
                context.insert(StoreValueEntity(key: key, payload: payload))
            }
            try commit(context)
        } catch {
            context.rollback()
            throw AppError.storageWrite
        }
    }

    private func entity(key: String, context: ModelContext) throws -> StoreValueEntity? {
        let descriptor = FetchDescriptor<StoreValueEntity>(predicate: #Predicate { $0.key == key })
        let values = try context.fetch(descriptor)
        guard values.count <= 1 else { throw AppError.invalidStoredData }
        return values.first
    }
}
