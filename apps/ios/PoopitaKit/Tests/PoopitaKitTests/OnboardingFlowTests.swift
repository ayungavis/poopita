import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct OnboardingFlowTests {
    private static let zone = TimeZone(secondsFromGMT: 0) ?? .gmt
    private static let now = Date(timeIntervalSince1970: 1_793_440_860)

    private static func defaults() throws -> UserDefaults {
        let suite = "OnboardingFlowTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    private static func model(_ defaults: UserDefaults, diary: any DiaryRepository) -> OnboardingViewModel {
        OnboardingViewModel(
            repository: LocalOnboardingRepository(store: UserDefaultsValueStore(defaults: defaults)), diary: diary,
            now: { now }, timeZone: { zone }
        )
    }

    @Test func aNewDiaryWalksTheThreeStepsOnceAndNeverAgain() throws {
        let defaults = try Self.defaults()
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let diary = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let model = Self.model(defaults, diary: diary)
        #expect(model.isPresented)
        #expect(model.state.step == .welcome)
        #expect(model.state.progressLabel == "Step 1 of 3")

        model.next()
        #expect(model.state.step == .marks)
        model.next()
        #expect(model.state.step == .reminder)
        #expect(model.isPresented)
        model.next()
        #expect(!model.isPresented)

        #expect(!Self.model(defaults, diary: diary).isPresented)
    }

    @Test func skippingFinishesAndAnExistingDiaryNeverSeesIt() throws {
        let defaults = try Self.defaults()
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let diary = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let skipped = Self.model(defaults, diary: diary)
        skipped.finish()
        #expect(!Self.model(defaults, diary: diary).isPresented)

        let upgraded = try Self.defaults()
        try diary.saveCheckIn(NoPoopCheckIn(
            day: DiaryDay(year: 2026, month: 10, day: 30),
            reportedAt: OccurrenceTime(instant: Self.now, timeZone: Self.zone), coverage: .completed
        ))
        #expect(!Self.model(upgraded, diary: diary).isPresented)
        #expect(LocalOnboardingRepository(store: UserDefaultsValueStore(defaults: upgraded)).isFinished())
    }

    @Test func anUnreadableFlagDoesNotShowItAgain() throws {
        let defaults = try Self.defaults()
        defaults.set(Data("not json".utf8), forKey: LocalOnboardingRepository.finishedKey)
        #expect(LocalOnboardingRepository(store: UserDefaultsValueStore(defaults: defaults)).isFinished())
    }

    @Test func theSampleWeekEndsTodayAndShowsEveryMark() {
        let data = OnboardingViewModel.viewData(step: .marks, now: Self.now, timeZone: Self.zone)
        #expect(data.sampleWeek.map(\.mark) == [.logs(1), .logs(2), .noPoop, .unrecorded, .logs(1)])
        #expect(data.sampleWeek.map(\.isToday) == [false, false, false, false, true])
        var day = Date.FormatStyle.dateTime.day()
        day.timeZone = Self.zone
        #expect(data.sampleWeek.last?.dayNumber == Self.now.formatted(day))
        #expect(data.progressLabel == "Step 2 of 3")
    }
}
