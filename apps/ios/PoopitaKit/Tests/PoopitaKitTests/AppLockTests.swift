import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct AppLockTests {
    private static let start = Date(timeIntervalSince1970: 1_793_440_860)

    static func model(
        biometric: TestBiometricService = TestBiometricService(), diary: any DiaryRepository,
        defaults: UserDefaults? = nil, now: @escaping () -> Date = { .now }
    ) -> AppLockModel {
        let store = defaults ?? UserDefaults(suiteName: "AppLockTests.\(UUID().uuidString)") ?? UserDefaults()
        return AppLockModel(
            repository: LocalAppLockRepository(store: UserDefaultsValueStore(defaults: store)), diary: diary,
            biometricService: biometric, now: now
        )
    }

    private static func defaults() throws -> UserDefaults {
        let suite = "AppLockTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    private static func diary() throws -> LocalDiaryRepository {
        try LocalDiaryRepository(store: SwiftDataValueStore(
            directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        ))
    }

    @Test func turningItOnNeedsAuthenticationAndSurvivesARelaunchLocked() async throws {
        let defaults = try Self.defaults()
        let diary = try Self.diary()
        let biometric = TestBiometricService()
        let model = Self.model(biometric: biometric, diary: diary, defaults: defaults)
        #expect(!model.isEnabled && !model.isLocked)

        biometric.shouldSucceed = false
        #expect(await model.setEnabled(true) == false)
        #expect(!Self.model(diary: diary, defaults: defaults).isEnabled)

        biometric.shouldSucceed = true
        #expect(await model.setEnabled(true))
        #expect(!model.isLocked)

        let relaunched = Self.model(biometric: biometric, diary: diary, defaults: defaults)
        #expect(relaunched.isEnabled && relaunched.isLocked)
        biometric.shouldSucceed = false
        await relaunched.unlock()
        #expect(relaunched.isLocked)
        biometric.shouldSucceed = true
        await relaunched.unlock()
        #expect(!relaunched.isLocked)
    }

    @Test func comingBackWithinAMinuteStaysOpenAndLaterLocks() async throws {
        let defaults = try Self.defaults()
        var now = Self.start
        let model = try Self.model(diary: Self.diary(), defaults: defaults) { now }
        #expect(await model.setEnabled(true))

        model.didEnterBackground()
        now += AppLockModel.gracePeriod - 1
        model.willEnterForeground()
        #expect(!model.isLocked)

        model.didEnterBackground()
        now += AppLockModel.gracePeriod
        model.willEnterForeground()
        #expect(model.isLocked)
    }

    @Test func offersOnceAfterTheThirdLog() throws {
        let defaults = try Self.defaults()
        let diary = try Self.diary()
        let model = Self.model(diary: diary, defaults: defaults)
        for index in 0 ..< AppLockModel.offerAfterLogs {
            model.considerOffer()
            #expect(!model.isOffering)
            try diary.save(DiaryEntry(
                id: UUID(), occurrence: OccurrenceTime(instant: Self.start + Double(index) * 3600, timeZone: .gmt),
                stoolType: 4, amount: nil, effort: nil, note: ""
            ))
        }
        model.considerOffer()
        #expect(model.isOffering)

        model.declineOffer()
        model.considerOffer()
        #expect(!model.isOffering)
        let relaunched = Self.model(diary: diary, defaults: defaults)
        relaunched.considerOffer()
        #expect(!relaunched.isOffering)
    }

    @Test func aDeviceWithoutAPasscodeNeverLocksOrOffers() throws {
        let defaults = try Self.defaults()
        try LocalAppLockRepository(store: UserDefaultsValueStore(defaults: defaults)).setEnabled(true)
        let biometric = TestBiometricService()
        biometric.available = false
        let model = try Self.model(biometric: biometric, diary: Self.diary(), defaults: defaults)
        #expect(!model.isEnabled && !model.isLocked)
    }

    @Test func anUnreadableSettingFailsClosed() throws {
        let defaults = try Self.defaults()
        defaults.set(Data("not json".utf8), forKey: LocalAppLockRepository.enabledKey)
        let model = try Self.model(diary: Self.diary(), defaults: defaults)
        #expect(model.isLocked)
    }
}
