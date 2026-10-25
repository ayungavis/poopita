import Foundation

@MainActor
public final class AppContainer {
    private var diary: (any DiaryRepository)?

    public init() {}

    func makeTodayViewModel() throws -> TodayViewModel {
        if let diary {
            return TodayViewModel(repository: diary, now: { .now }, timeZone: { .current })
        }
        let directory = try ProtectedStorage.directory(named: "Diary")
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        diary = repository
        return TodayViewModel(repository: repository, now: { .now }, timeZone: { .current })
    }
}
