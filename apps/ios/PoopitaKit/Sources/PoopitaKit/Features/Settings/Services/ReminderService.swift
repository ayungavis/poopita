import Foundation
import UserNotifications

@MainActor
protocol ReminderService: Sendable {
    func requestAuthorization() async -> Bool
    func checkAuthorizationStatus() async -> Bool
    func scheduleDailyReminder(hour: Int, minute: Int, skipToday: Bool) async throws
    func cancelDailyReminder() async
}

@MainActor
final class UserNotificationsReminderService: ReminderService {
    private static let identifier = "poopita.dailyReminder"

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    func checkAuthorizationStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func scheduleDailyReminder(hour: Int, minute: Int, skipToday _: Bool) async throws {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Poopita"
        content.body = String(localized: "settings.reminders.notificationBody", bundle: .module)
        content.sound = .default
        let request = UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    func cancelDailyReminder() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.identifier])
    }
}
