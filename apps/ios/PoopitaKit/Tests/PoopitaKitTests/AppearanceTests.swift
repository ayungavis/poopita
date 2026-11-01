import Foundation
@testable import PoopitaKit
import SwiftUI
import Testing

@MainActor
struct AppearanceTests {
    private static func defaults() throws -> UserDefaults {
        let suite = "AppearanceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    static func model() throws -> AppearanceModel {
        try AppearanceModel(repository: LocalAppearanceRepository(store: UserDefaultsValueStore(defaults: defaults())))
    }

    @Test func themeDefaultsToSystemAndSurvivesARelaunch() throws {
        let defaults = try Self.defaults()
        let model = AppearanceModel(repository: LocalAppearanceRepository(store: UserDefaultsValueStore(defaults: defaults)))
        #expect(model.colorScheme == nil)

        try model.setTheme(.dark)
        #expect(model.colorScheme == .dark)

        let relaunched = AppearanceModel(
            repository: LocalAppearanceRepository(store: UserDefaultsValueStore(defaults: defaults))
        )
        #expect(relaunched.colorScheme == .dark)
    }

    @Test func anUnreadableStoredThemeFallsBackToSystem() throws {
        let defaults = try Self.defaults()
        defaults.set(Data("not json".utf8), forKey: LocalAppearanceRepository.themeKey)
        let repository = LocalAppearanceRepository(store: UserDefaultsValueStore(defaults: defaults))
        #expect(repository.theme() == .system)
    }

    @Test func settingsShowsTheChosenThemeAndIgnoresAnUnknownOne() throws {
        let defaults = try Self.defaults()
        let appearance = AppearanceModel(
            repository: LocalAppearanceRepository(store: UserDefaultsValueStore(defaults: defaults))
        )
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let model = Self.settings(repository: repository, appearance: appearance, language: TestLanguageService())
        #expect(model.state.appearance.selectedThemeID == "system")
        #expect(model.state.appearance.themes.map(\.id) == ["system", "light", "dark"])

        model.selectTheme(id: "light")
        #expect(model.state.appearance.selectedThemeID == "light")
        #expect(appearance.colorScheme == .light)

        model.selectTheme(id: "sepia")
        #expect(model.state.appearance.selectedThemeID == "light")
    }

    @Test func pickingAnotherLanguageAsksFirstAndOnlyConfirmingRelaunches() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let language = TestLanguageService()
        let model = try Self.settings(repository: repository, appearance: Self.model(), language: language)
        #expect(model.state.appearance.languages.map(\.id) == ["en", "id"])
        #expect(model.state.appearance.selectedLanguageID == "en")

        model.selectLanguage(id: "en")
        model.selectLanguage(id: "fr")
        #expect(model.state.appearance.languageChange == nil)

        model.selectLanguage(id: "id")
        #expect(model.state.appearance.languageChange?.title.contains("Indonesia") == true)
        #expect(model.state.appearance.selectedLanguageID == "en")
        #expect(language.relaunchedIn == nil)

        model.cancelLanguageChange()
        #expect(model.state.appearance.languageChange == nil)
        #expect(language.relaunchedIn == nil)

        model.selectLanguage(id: "id")
        model.confirmLanguageChange()
        #expect(language.relaunchedIn == "id")
        #expect(model.state.appearance.languageChange == nil)
    }

    @Test func readsTheSavedLanguageAndIgnoresOnesTheAppLacks() throws {
        let defaults = try Self.defaults()
        let service = AppleLanguagesService(defaults: defaults)
        defaults.set(["id-ID"], forKey: "AppleLanguages")
        #expect(service.chosenCode == "id")
        defaults.set(["fr-FR"], forKey: "AppleLanguages")
        #expect(service.chosenCode == service.activeCode)
        defaults.set(["en"], forKey: "AppleLanguages")
        #expect(service.chosenCode == "en")
    }

    @Test func theFooterNamesTheAppVersionAndFallsBackWithoutOne() {
        #expect(SettingsViewModel.footer(version: "2.3").contains("Poopita 2.3"))
        #expect(SettingsViewModel.footer(version: nil).contains("Poopita 1.0"))
    }

    @Test func namesTheAppLanguageInThatLanguage() {
        #expect(SettingsViewModel.languageName(code: "en") == "English")
        #expect(SettingsViewModel.languageName(code: "id") == "Indonesia")
    }

    private static func settings(
        repository: LocalDiaryRepository, appearance: AppearanceModel, language: TestLanguageService
    ) -> SettingsViewModel {
        SettingsViewModel(
            repository: repository, undoModel: UndoModel(repository: repository), appearance: appearance,
            reminderService: TestReminderService(), biometricService: TestBiometricService(),
            languageService: language, now: { .now }, timeZone: { .gmt }
        )
    }
}

@MainActor
final class TestLanguageService: LanguageService {
    let availableCodes = ["en", "id"]
    let activeCode = "en"
    let chosenCode = "en"
    private(set) var relaunchedIn: String?

    func relaunch(in code: String) {
        relaunchedIn = code
    }
}
