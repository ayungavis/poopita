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
    private let reminderService: any ReminderService
    private let biometricService: any BiometricService
    private let languageService: any LanguageService
    private let now: () -> Date
    private let timeZone: () -> TimeZone
    private var reminderTime: Date
    private var pendingLanguage: String?

    init(
        repository: any DiaryRepository,
        undoModel: UndoModel,
        appearance: AppearanceModel,
        reminderService: any ReminderService,
        biometricService: any BiometricService,
        languageService: any LanguageService,
        now: @escaping () -> Date,
        timeZone: @escaping () -> TimeZone
    ) {
        self.repository = repository
        self.undoModel = undoModel
        self.appearance = appearance
        self.reminderService = reminderService
        self.biometricService = biometricService
        self.languageService = languageService
        self.now = now
        self.timeZone = timeZone
        footer = Self.footer(version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone()
        let initialTime = calendar.date(from: DateComponents(hour: 20, minute: 0)) ?? now()
        reminderTime = initialTime
        state = Self.viewData(
            isReminderEnabled: false,
            reminderDate: initialTime,
            isAppLockEnabled: false,
            isBiometricsAvailable: biometricService.isAvailable(),
            appearance: Self.appearanceViewData(appearance: appearance, language: languageService, pending: nil)
        )
    }

    func toggleReminder(_ enabled: Bool) async {
        if enabled {
            var authorized = await reminderService.checkAuthorizationStatus()
            if !authorized {
                authorized = await reminderService.requestAuthorization()
            }
            guard authorized else {
                errorMessage = String(localized: "settings.reminders.denied", bundle: .module)
                return
            }
            await scheduleCurrentReminder()
            updateState(reminderEnabled: true)
        } else {
            await reminderService.cancelDailyReminder()
            updateState(reminderEnabled: false)
        }
    }

    func setReminderDate(_ date: Date) async {
        reminderTime = date
        if state.isReminderEnabled {
            await scheduleCurrentReminder()
        }
        updateState(reminderDate: date)
    }

    func toggleAppLock(_ enabled: Bool) async {
        guard enabled != state.isAppLockEnabled else { return }
        if enabled {
            let reason = String(localized: "settings.appLock.reason", bundle: .module)
            let success = await biometricService.authenticate(reason: reason)
            if success {
                updateState(appLockEnabled: true)
                undoModel.record(String(localized: "settings.appLock.enabled", bundle: .module), undoable: false)
            } else {
                errorMessage = String(localized: "settings.appLock.failed", bundle: .module)
            }
        } else {
            let reason = String(localized: "settings.appLock.disableReason", bundle: .module)
            let success = await biometricService.authenticate(reason: reason)
            if success {
                updateState(appLockEnabled: false)
                undoModel.record(String(localized: "settings.appLock.disabled", bundle: .module), undoable: false)
            } else {
                errorMessage = String(localized: "settings.appLock.failed", bundle: .module)
            }
        }
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

    func updateReminderSchedule() async {
        guard state.isReminderEnabled else { return }
        await scheduleCurrentReminder()
    }

    func deleteAllHistory() throws {
        try repository.deleteAll()
        undoModel.record(String(localized: "settings.history.deleted", bundle: .module))
    }

    func authenticateToUnlock() async -> Bool {
        let reason = String(localized: "settings.appLock.reason", bundle: .module)
        return await biometricService.authenticate(reason: reason)
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

    private func scheduleCurrentReminder() async {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone()
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)
        let skipToday = hasObservationToday()
        do {
            try await reminderService.scheduleDailyReminder(hour: hour, minute: minute, skipToday: skipToday)
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }

    private func hasObservationToday() -> Bool {
        guard let today = try? DiaryDay(date: now(), timeZone: timeZone()) else { return false }
        let hasEntry = (try? repository.entries())?.contains { DiaryDay(occurrence: $0.occurrence) == today } ?? false
        let hasCheckIn = (try? repository.checkIns())?.contains { $0.day == today && $0.coverage == .completed } ?? false
        return hasEntry || hasCheckIn
    }

    private func updateState(
        reminderEnabled: Bool? = nil,
        reminderDate: Date? = nil,
        appLockEnabled: Bool? = nil
    ) {
        state = Self.viewData(
            isReminderEnabled: reminderEnabled ?? state.isReminderEnabled,
            reminderDate: reminderDate ?? state.reminderDate,
            isAppLockEnabled: appLockEnabled ?? state.isAppLockEnabled,
            isBiometricsAvailable: state.isBiometricsAvailable,
            appearance: Self.appearanceViewData(
                appearance: appearance, language: languageService, pending: pendingLanguage
            )
        )
    }
}

extension SettingsViewModel {
    static func viewData(
        isReminderEnabled: Bool,
        reminderDate: Date,
        isAppLockEnabled: Bool,
        isBiometricsAvailable: Bool,
        appearance: SettingsAppearanceViewData
    ) -> SettingsViewData {
        SettingsViewData(
            isReminderEnabled: isReminderEnabled,
            reminderDate: reminderDate,
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

    static var guide: SettingsGuideViewData {
        let rows = EntryChoiceViewData.types.map { type in
            SettingsGuideViewData.Row(
                id: type.id, title: type.title + " · " + type.detail,
                description: String(
                    localized: String.LocalizationValue("settings.guide.desc" + type.id), bundle: .module
                ),
                illustration: type.illustration
            )
        }
        let group = { (id: String, title: String, range: Range<Int>) in
            SettingsGuideViewData.Group(id: id, title: title, rows: Array(rows[range]))
        }
        return SettingsGuideViewData(
            intro: String(localized: "settings.guide.intro", bundle: .module),
            groups: [
                group("harder", String(localized: "settings.guide.harder", bundle: .module), 0 ..< 2),
                group("typical", String(localized: "settings.guide.typical", bundle: .module), 2 ..< 4),
                group("looser", String(localized: "settings.guide.looser", bundle: .module), 4 ..< 7),
            ],
            note: String(localized: "settings.guide.note", bundle: .module)
        )
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
