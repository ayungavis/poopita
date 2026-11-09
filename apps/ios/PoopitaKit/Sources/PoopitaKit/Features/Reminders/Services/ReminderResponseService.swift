import Foundation
import UserNotifications

@MainActor
protocol ReminderResponseService: AnyObject {
    var onResponse: ((ReminderResponse) async -> Void)? { get set }
}

@MainActor
final class UserNotificationsResponseService: NSObject, ReminderResponseService, UNUserNotificationCenterDelegate {
    var onResponse: ((ReminderResponse) async -> Void)?

    override init() {
        super.init()
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories(Self.categories())
        center.delegate = self
    }

    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter, didReceive response: UNNotificationResponse
    ) async {
        let action = response.actionIdentifier
        let category = response.notification.request.content.categoryIdentifier
        guard let reminder = ReminderCategory.response(action: action, category: category) else { return }
        await deliver(reminder)
    }

    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter, willPresent _: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    private func deliver(_ response: ReminderResponse) async {
        await onResponse?(response)
    }

    private static func categories() -> Set<UNNotificationCategory> {
        let logNow = UNNotificationAction(
            identifier: ReminderCategory.logNow, title: String(localized: "reminders.action.logNow", bundle: .module),
            options: .foreground, icon: UNNotificationActionIcon(systemImageName: "plus")
        )
        let snooze = UNNotificationAction(
            identifier: ReminderCategory.snooze, title: String(localized: "reminders.action.snooze", bundle: .module),
            options: [], icon: UNNotificationActionIcon(systemImageName: "clock")
        )
        return [
            UNNotificationCategory(
                identifier: ReminderCategory.daily, actions: [logNow, snooze], intentIdentifiers: []
            ),
            UNNotificationCategory(
                identifier: ReminderCategory.dailyLastCall, actions: [logNow], intentIdentifiers: []
            ),
            UNNotificationCategory(identifier: ReminderCategory.weeklySummary, actions: [], intentIdentifiers: []),
            UNNotificationCategory(identifier: ReminderCategory.gap, actions: [logNow], intentIdentifiers: []),
        ]
    }
}
