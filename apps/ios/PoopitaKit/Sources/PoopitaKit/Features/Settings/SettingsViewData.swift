import Foundation

struct SettingsViewData: Equatable, Sendable {
    let isAppLockEnabled: Bool
    let isBiometricsAvailable: Bool
    let appearance: SettingsAppearanceViewData
}

struct SettingsLinksViewData: Equatable, Sendable {
    let privacyPolicy: URL
    let support: URL
}

struct SettingsAppearanceViewData: Equatable, Sendable {
    let themes: [SettingsChoiceViewData]
    let selectedThemeID: String
    let languages: [SettingsChoiceViewData]
    let selectedLanguageID: String
    let languageName: String
    let languageChange: SettingsLanguageChangeViewData?
    let hidesInAppSwitcher: Bool
}

struct SettingsLanguageChangeViewData: Equatable, Sendable {
    let title: String
    let message: String
}

struct SettingsChoiceViewData: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
}

struct SettingsDeleteViewData: Equatable, Sendable {
    let logs: String
    let checkIns: String
    let since: String?
    let isEmpty: Bool
    let confirmWord: String
}
