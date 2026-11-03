import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private(set) var state: SettingsViewData
    private(set) var errorMessage: String?
    let footer: String
    private let repository: any DiaryRepository
    private let undoModel: UndoModel
    private let appearance: AppearanceModel
    private let appLock: AppLockModel
    private let languageService: any LanguageService
    private let now: () -> Date
    private var pendingLanguage: String?

    init(
        repository: any DiaryRepository,
        undoModel: UndoModel,
        appearance: AppearanceModel,
        appLock: AppLockModel,
        languageService: any LanguageService,
        now: @escaping () -> Date
    ) {
        self.repository = repository
        self.undoModel = undoModel
        self.appearance = appearance
        self.appLock = appLock
        self.languageService = languageService
        self.now = now
        footer = Self.footer(version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)

        state = Self.viewData(
            isAppLockEnabled: appLock.isEnabled,
            isBiometricsAvailable: appLock.isAvailable,
            appearance: Self.appearanceViewData(appearance: appearance, language: languageService, pending: nil)
        )
    }

    func toggleAppLock(_ enabled: Bool) async {
        guard enabled != state.isAppLockEnabled else { return }
        guard await appLock.setEnabled(enabled) else {
            errorMessage = String(localized: "settings.appLock.failed", bundle: .module)
            return
        }
        errorMessage = nil
        updateState()
        let key: String.LocalizationValue = enabled ? "settings.appLock.enabled" : "settings.appLock.disabled"
        undoModel.record(String(localized: key, bundle: .module), undoable: false)
    }

    func refresh() {
        updateState()
    }

    func selectTheme(id: String) {
        guard let theme = AppTheme(rawValue: id) else { return }
        do {
            try appearance.setTheme(theme)
            updateState()
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }

    func selectLanguage(id: String) {
        guard id != languageService.chosenCode, languageService.availableCodes.contains(id) else { return }
        pendingLanguage = id
        updateState()
    }

    func setHidesInAppSwitcher(_ hides: Bool) {
        do {
            try appearance.setHidesInAppSwitcher(hides)
            updateState()
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }

    var csvExport: SettingsExportViewData {
        SettingsExportViewData(fileName: "poopita-diary.csv", isPDF: false) { [weak self] in
            self?.exportData { Data(DiaryCSV.make(entries: $0, checkIns: $1).utf8) } ?? Data()
        }
    }

    var pdfExport: SettingsExportViewData {
        SettingsExportViewData(fileName: "poopita-report.pdf", isPDF: true) { [weak self] in
            guard let self else { return Data() }
            let date = now()
            return exportData { DiaryReport(entries: $0, checkIns: $1, now: date).pdf() }
        }
    }

    func cancelLanguageChange() {
        pendingLanguage = nil
        updateState()
    }

    func confirmLanguageChange() {
        guard let code = pendingLanguage else { return }
        pendingLanguage = nil
        updateState()
        languageService.relaunch(in: code)
    }

    func deleteViewData() -> SettingsDeleteViewData {
        Self.deleteViewData(entries: (try? repository.entries()) ?? [], checkIns: (try? repository.checkIns()) ?? [])
    }

    func deleteAllHistory() throws {
        try repository.deleteAll()
        undoModel.record(String(localized: "settings.history.deleted", bundle: .module))
    }

    private func exportData(_ make: ([DiaryEntry], [NoPoopCheckIn]) -> Data) -> Data {
        do {
            return try make(repository.entries(), repository.checkIns())
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
            Log.report(error, context: Log.Context(operation: "settings.export"))
            return Data()
        }
    }

    private func updateState() {
        state = Self.viewData(
            isAppLockEnabled: appLock.isEnabled,
            isBiometricsAvailable: appLock.isAvailable,
            appearance: Self.appearanceViewData(
                appearance: appearance, language: languageService, pending: pendingLanguage
            )
        )
    }
}

extension SettingsViewModel {
    static func viewData(
        isAppLockEnabled: Bool,
        isBiometricsAvailable: Bool,
        appearance: SettingsAppearanceViewData
    ) -> SettingsViewData {
        SettingsViewData(
            isAppLockEnabled: isAppLockEnabled,
            isBiometricsAvailable: isBiometricsAvailable,
            appearance: appearance
        )
    }

    static func appearanceViewData(
        appearance: AppearanceModel, language: any LanguageService, pending: String?
    ) -> SettingsAppearanceViewData {
        let theme = appearance.theme
        let chosen = language.chosenCode
        return SettingsAppearanceViewData(
            themes: AppTheme.allCases.map { SettingsChoiceViewData(id: $0.rawValue, title: title(for: $0)) },
            selectedThemeID: theme.rawValue,
            languages: language.availableCodes.map { SettingsChoiceViewData(id: $0, title: languageName(code: $0)) },
            selectedLanguageID: chosen,
            languageName: languageName(code: chosen),
            languageChange: pending.map(languageName).map { name in
                SettingsLanguageChangeViewData(
                    title: String(localized: "settings.appearance.switchTitle \(name)", bundle: .module),
                    message: String(localized: "settings.appearance.switchMessage \(name)", bundle: .module)
                )
            },
            hidesInAppSwitcher: appearance.hidesInAppSwitcher
        )
    }

    static func deleteViewData(entries: [DiaryEntry], checkIns: [NoPoopCheckIn]) -> SettingsDeleteViewData {
        let first = (entries.map(\.occurrence.instant) + checkIns.map(\.reportedAt.instant)).min()
        return SettingsDeleteViewData(
            logs: entries.count.formatted(), checkIns: checkIns.count.formatted(),
            since: first?.formatted(.dateTime.day().month(.abbreviated).year()),
            isEmpty: entries.isEmpty && checkIns.isEmpty,
            confirmWord: String(localized: "settings.delete.confirmWord", bundle: .module)
        )
    }

    static func confirms(_ typed: String, word: String) -> Bool {
        let answer = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        return answer.caseInsensitiveCompare(word) == .orderedSame
    }

    static func footer(version: String?) -> String {
        String(localized: "settings.footer \(version ?? "1.0")", bundle: .module)
    }

    static func languageName(code: String) -> String {
        let locale = Locale(identifier: code)
        return locale.localizedString(forLanguageCode: code)?.capitalized(with: locale) ?? code
    }

    private static func title(for theme: AppTheme) -> String {
        switch theme {
        case .system: String(localized: "settings.appearance.system", bundle: .module)
        case .light: String(localized: "settings.appearance.light", bundle: .module)
        case .dark: String(localized: "settings.appearance.dark", bundle: .module)
        }
    }
}
