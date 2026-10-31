import DesignSystem
import Foundation

@MainActor
public final class AppContainer {
    private var diary: (any DiaryRepository)?

    public init() {
        AppFont.registerFonts()
    }

    func makeTodayViewModel() throws -> TodayViewModel {
        try TodayViewModel(repository: diaryRepository(), now: { .now }, timeZone: { .current })
    }

    func makeHistoryViewModel() throws -> HistoryViewModel {
        try HistoryViewModel(repository: diaryRepository(), now: { .now }, timeZone: { .current })
    }

    func makePatternsViewModel() throws -> PatternsViewModel {
        try PatternsViewModel(repository: diaryRepository(), now: { .now }, timeZone: { .current })
    }

    func makeSettingsViewModel() throws -> SettingsViewModel {
        try SettingsViewModel(
            repository: diaryRepository(),
            reminderService: UserNotificationsReminderService(),
            biometricService: LocalAuthenticationBiometricService(),
            now: { .now },
            timeZone: { .current }
        )
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
