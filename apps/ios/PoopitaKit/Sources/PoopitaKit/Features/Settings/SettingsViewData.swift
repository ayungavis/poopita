import Foundation

struct SettingsViewData: Equatable, Sendable {
    let isReminderEnabled: Bool
    let reminderDate: Date
    let isAppLockEnabled: Bool
    let isBiometricsAvailable: Bool
}
