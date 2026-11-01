import Foundation

@MainActor
protocol AppearanceRepository {
    func theme() -> AppTheme
    func setTheme(_ theme: AppTheme) throws
}

@MainActor
final class LocalAppearanceRepository: AppearanceRepository {
    static let themeKey = "appearance.theme"
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
}
