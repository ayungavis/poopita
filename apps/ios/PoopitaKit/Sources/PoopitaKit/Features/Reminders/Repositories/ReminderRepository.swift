import Foundation

@MainActor
protocol ReminderRepository {
    func preferences() -> ReminderPreferences
    func save(_ preferences: ReminderPreferences) throws
    func snooze() -> ReminderSnooze?
    func save(_ snooze: ReminderSnooze) throws
}

@MainActor
final class LocalReminderRepository: ReminderRepository {
    static let key = "reminders.preferences"
    static let snoozeKey = "reminders.snooze"
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

    func snooze() -> ReminderSnooze? {
        do {
            return try store.read(ReminderSnooze.self, key: Self.snoozeKey)
        } catch {
            Log.report(error, context: Log.Context(operation: "reminders.read"))
            return nil
        }
    }

    func save(_ snooze: ReminderSnooze) throws {
        try store.write(snooze, key: Self.snoozeKey)
    }
}
