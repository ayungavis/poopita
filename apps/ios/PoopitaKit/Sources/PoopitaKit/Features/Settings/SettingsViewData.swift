import Foundation

struct SettingsViewData: Equatable, Sendable {
    let isReminderEnabled: Bool
    let reminderDate: Date
    let isAppLockEnabled: Bool
    let isBiometricsAvailable: Bool
    let appearance: SettingsAppearanceViewData
}

struct SettingsAppearanceViewData: Equatable, Sendable {
    let themes: [SettingsChoiceViewData]
    let selectedThemeID: String
    let languages: [SettingsChoiceViewData]
    let selectedLanguageID: String
    let languageName: String
    let languageNote: String?
}

struct SettingsChoiceViewData: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
}
