import Foundation

struct SettingsViewData: Equatable, Sendable {
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

struct SettingsGuideViewData: Equatable, Sendable {
    struct Group: Identifiable, Equatable, Sendable {
        let id: String
        let title: String
        let rows: [Row]
    }

    struct Row: Identifiable, Equatable, Sendable {
        let id: String
        let title: String
        let description: String
        let illustration: EntryIllustrationKind?
    }

    let intro: String
    let groups: [Group]
    let note: String
}
