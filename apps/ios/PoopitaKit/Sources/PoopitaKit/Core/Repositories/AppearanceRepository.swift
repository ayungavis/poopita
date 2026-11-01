import Foundation

@MainActor
protocol AppearanceRepository {
    func theme() -> AppTheme
    func setTheme(_ theme: AppTheme) throws
    func hidesInAppSwitcher() -> Bool
    func setHidesInAppSwitcher(_ hides: Bool) throws
}

@MainActor
final class LocalAppearanceRepository: AppearanceRepository {
    static let themeKey = "appearance.theme"
    static let switcherKey = "appearance.hidesInAppSwitcher"
    private let store: any ValueStore

    init(store: any ValueStore) {
        self.store = store
    }

    func theme() -> AppTheme {
        do {
            return try store.read(AppTheme.self, key: Self.themeKey) ?? .system
        } catch {
            Log.report(error, context: Log.Context(operation: "appearance.read"))
            return .system
        }
    }

    func setTheme(_ theme: AppTheme) throws {
        try store.write(theme, key: Self.themeKey)
    }

    func hidesInAppSwitcher() -> Bool {
        do {
            return try store.read(Bool.self, key: Self.switcherKey) ?? true
        } catch {
            Log.report(error, context: Log.Context(operation: "appearance.read"))
            return true
        }
    }

    func setHidesInAppSwitcher(_ hides: Bool) throws {
        try store.write(hides, key: Self.switcherKey)
    }
}
