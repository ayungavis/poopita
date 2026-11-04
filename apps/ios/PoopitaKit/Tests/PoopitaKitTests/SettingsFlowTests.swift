import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct SettingsFlowTests {
    @Test func togglingAppLockAuthenticatesWithBiometrics() async throws {
        let biometric = TestBiometricService()
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: fixture()))
        let clock = try date("2026-10-20T12:00:00Z")

        let model = try SettingsViewModel(
            repository: repository, undoModel: UndoModel(repository: repository), appearance: AppearanceTests.model(),
            appLock: AppLockTests.model(biometric: biometric, diary: repository), languageService: TestLanguageService(),
            now: { clock }
        )

        biometric.shouldSucceed = false
        await model.toggleAppLock(true)
        #expect(biometric.didAuthenticate)
        #expect(model.state.isAppLockEnabled == false)

        biometric.shouldSucceed = true
        await model.toggleAppLock(true)
        #expect(model.state.isAppLockEnabled == true)
    }

    @Test func deleteAllHistoryClearsStoreAndSupportsUndo() throws {
        let biometric = TestBiometricService()
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: fixture()))
        let clock = try date("2026-10-20T12:00:00Z")
        let zone = try #require(TimeZone(secondsFromGMT: 0))

        let entry = try makeEntry(day: clock, zone: zone)
        try repository.save(entry)
        let checkIn = try NoPoopCheckIn(
            day: DiaryDay(date: clock.addingTimeInterval(-86400), timeZone: zone),
            reportedAt: OccurrenceTime(instant: clock, timeZone: zone),
            coverage: .completed
        )
        try repository.saveCheckIn(checkIn)
        #expect(try repository.entries().count == 1)
        #expect(try repository.checkIns().count == 1)

        let undo = UndoModel(repository: repository)
        let model = try SettingsViewModel(
            repository: repository, undoModel: undo, appearance: AppearanceTests.model(),
            appLock: AppLockTests.model(biometric: biometric, diary: repository), languageService: TestLanguageService(),
            now: { clock }
        )

        try model.deleteAllHistory()
        #expect(try repository.entries().isEmpty)
        #expect(try repository.checkIns().isEmpty)

        undo.undo()
        #expect(try repository.entries().count == 1)
        #expect(try repository.checkIns().count == 1)
    }

    @Test(arguments: [
        ("en", "https://poopita.ayungavis.com/privacy/", "https://poopita.ayungavis.com/support/"),
        ("id", "https://poopita.ayungavis.com/id/privacy/", "https://poopita.ayungavis.com/id/support/"),
    ])
    func linksOpenThePolicyAndSupportPagesInTheAppLanguage(code: String, privacy: String, support: String) throws {
        let links = try #require(SettingsViewModel.links(languageCode: code))
        #expect(links.privacyPolicy.absoluteString == privacy)
        #expect(links.support.absoluteString == support)
    }

    private func makeEntry(day: Date, zone: TimeZone) throws -> DiaryEntry {
        let occurrence = try OccurrenceTime(instant: day, timeZone: zone)
        return DiaryEntry(id: UUID(), occurrence: occurrence, stoolType: 4, amount: nil, effort: nil, note: "")
    }

    private func date(_ value: String) throws -> Date {
        guard let date = ISO8601DateFormatter().date(from: value) else { throw AppError.invalidOccurrence }
        return date
    }

    private func fixture() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    }
}

@MainActor
final class TestBiometricService: BiometricService {
    var available = true
    var shouldSucceed = true
    var didAuthenticate = false

    func isAvailable() -> Bool {
        available
    }

    func method() -> AppLockMethod {
        .faceID
    }

    func authenticate(reason _: String) async -> Bool {
        didAuthenticate = true
        return shouldSucceed
    }
}
