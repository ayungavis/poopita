import Foundation

@MainActor
protocol AppLockRepository {
    func isEnabled() -> Bool
    func setEnabled(_ enabled: Bool) throws
    func wasOffered() -> Bool
    func markOffered() throws
}

@MainActor
final class LocalAppLockRepository: AppLockRepository {
    static let enabledKey = "appLock.enabled"
    static let offeredKey = "appLock.offered"
    private let store: any ValueStore

    init(store: any ValueStore) {
        self.store = store
    }

    func isEnabled() -> Bool {
        do {
            return try store.read(Bool.self, key: Self.enabledKey) ?? false
        } catch {
            Log.report(error, context: Log.Context(operation: "appLock.read"))
            return true
        }
    }

    func setEnabled(_ enabled: Bool) throws {
        try store.write(enabled, key: Self.enabledKey)
    }

    func wasOffered() -> Bool {
        do {
            return try store.read(Bool.self, key: Self.offeredKey) ?? false
        } catch {
            Log.report(error, context: Log.Context(operation: "appLock.read"))
            return true
        }
    }

    func markOffered() throws {
        try store.write(true, key: Self.offeredKey)
    }
}
