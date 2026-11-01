import Foundation
import UserNotifications

enum ReminderPermission: Equatable, Sendable {
    case notAsked, denied, allowed
}

@MainActor
protocol ReminderService {
    func permission() async -> ReminderPermission
    func requestPermission() async -> Bool
    func replace(with reminders: [PlannedReminder]) async throws
}

@MainActor
final class UserNotificationsReminderService: ReminderService {
    private static let prefix = "poopita."

    func permission() async -> ReminderPermission {
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: .allowed
        case .denied: .denied
        default: .notAsked
        }
    }

    func requestPermission() async -> Bool {
        await (try? UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func replace(with reminders: [PlannedReminder]) async throws {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(Self.prefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        for reminder in reminders {
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
            let content = UNMutableNotificationContent()
            (content.title, content.body) = Self.text(for: reminder.kind)
            content.sound = .default
            try await center.add(UNNotificationRequest(
                identifier: reminder.identifier, content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            ))
        }
    }

    static func text(for kind: PlannedReminder.Kind) -> (String, String) {
        switch kind {
        case .daily:
            (String(localized: "reminders.notificationTitle", bundle: .module),
             String(localized: "reminders.notificationBody", bundle: .module))
        case .weeklySummary:
            (String(localized: "reminders.summaryTitle", bundle: .module),
             String(localized: "reminders.summaryBody", bundle: .module))
        case .gap:
            (String(localized: "reminders.gapTitle", bundle: .module),
             String(localized: "reminders.gapBody", bundle: .module))
        }
    }
}
