import Foundation

@MainActor
protocol ReminderRepository {
    func preferences() -> ReminderPreferences
    func save(_ preferences: ReminderPreferences) throws
}

@MainActor
final class LocalReminderRepository: ReminderRepository {
    static let key = "reminders.preferences"
    private let store: any ValueStore

    init(store: any ValueStore) {
        self.store = store
    }

    func preferences() -> ReminderPreferences {
        do {
            return try store.read(ReminderPreferences.self, key: Self.key) ?? ReminderPreferences()
        } catch {
            Log.report(error, context: Log.Context(operation: "reminders.read"))
            return ReminderPreferences()
        }
    }

    func save(_ preferences: ReminderPreferences) throws {
        try store.write(preferences, key: Self.key)
    }
}
