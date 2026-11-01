import DesignSystem
import Foundation

@MainActor
public final class AppContainer {
    private var diary: (any DiaryRepository)?
    private var undo: UndoModel?
    private var appearance: AppearanceModel?

    public init() {
        AppFont.registerFonts()
        #if os(iOS)
            NavigationBarStyle.apply()
        #endif
    }

    func makeTodayViewModel() throws -> TodayViewModel {
        try TodayViewModel(repository: diaryRepository(), undoModel: undoModel(), now: { .now }, timeZone: { .current })
    }

    func makeHistoryViewModel() throws -> HistoryViewModel {
        try HistoryViewModel(repository: diaryRepository(), undoModel: undoModel(), now: { .now }, timeZone: { .current })
    }

    func makePatternsViewModel() throws -> PatternsViewModel {
        try PatternsViewModel(repository: diaryRepository(), now: { .now }, timeZone: { .current })
    }

    func makeSettingsViewModel() throws -> SettingsViewModel {
        try SettingsViewModel(
            repository: diaryRepository(),
            undoModel: undoModel(),
            appearance: appearanceModel(),
            reminderService: UserNotificationsReminderService(),
            biometricService: LocalAuthenticationBiometricService(),
            languageService: AppleLanguagesService(),
            now: { .now },
            timeZone: { .current }
        )
    }

    func appearanceModel() -> AppearanceModel {
        if let appearance {
            return appearance
        }
        let model = AppearanceModel(repository: LocalAppearanceRepository(store: UserDefaultsValueStore()))
        appearance = model
        return model
    }

    func undoModel() throws -> UndoModel {
        if let undo {
            return undo
        }
        let model = try UndoModel(repository: diaryRepository())
        undo = model
        return model
    }

    private func diaryRepository() throws -> any DiaryRepository {
        if let diary {
            return diary
        }
        let directory = try ProtectedStorage.directory(named: "Diary")
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        diary = repository
        return repository
    }
}
