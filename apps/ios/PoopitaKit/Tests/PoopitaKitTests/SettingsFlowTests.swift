import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct SettingsFlowTests {
    @Test func togglingReminderSchedulesAndCancelsViaReminderService() async throws {
        let reminder = TestReminderService()
        let biometric = TestBiometricService()
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: fixture()))
        let clock = try date("2026-10-20T12:00:00Z")
        let zone = try #require(TimeZone(secondsFromGMT: 0))

        let model = SettingsViewModel(
            repository: repository, undoModel: UndoModel(repository: repository), reminderService: reminder,
            biometricService: biometric,
            now: { clock }, timeZone: { zone }
        )

        #expect(model.state.isReminderEnabled == false)
        await model.toggleReminder(true)
        #expect(reminder.requestedAuthorization)
        #expect(reminder.scheduledReminder != nil)
        #expect(model.state.isReminderEnabled == true)

        await model.toggleReminder(false)
        #expect(reminder.scheduledReminder == nil)
        #expect(reminder.cancelled)
        #expect(model.state.isReminderEnabled == false)
    }

    @Test func reminderSchedulingSkipsTodayIfEntryOrCheckInExists() async throws {
        let reminder = TestReminderService()
        let biometric = TestBiometricService()
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: fixture()))
        let clock = try date("2026-10-20T12:00:00Z")
        let zone = try #require(TimeZone(secondsFromGMT: 0))

        let model = SettingsViewModel(
            repository: repository, undoModel: UndoModel(repository: repository), reminderService: reminder,
            biometricService: biometric,
            now: { clock }, timeZone: { zone }
        )

        await model.toggleReminder(true)
        let firstSchedule = try #require(reminder.scheduledReminder)
        #expect(firstSchedule.skipToday == false)

        let entry = try makeEntry(day: clock, zone: zone)
        try repository.save(entry)

        await model.updateReminderSchedule()
        let secondSchedule = try #require(reminder.scheduledReminder)
        #expect(secondSchedule.skipToday == true)
    }

    @Test func togglingAppLockAuthenticatesWithBiometrics() async throws {
        let reminder = TestReminderService()
        let biometric = TestBiometricService()
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: fixture()))
        let clock = try date("2026-10-20T12:00:00Z")
        let zone = try #require(TimeZone(secondsFromGMT: 0))

        let model = SettingsViewModel(
            repository: repository, undoModel: UndoModel(repository: repository), reminderService: reminder,
            biometricService: biometric,
            now: { clock }, timeZone: { zone }
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
        let reminder = TestReminderService()
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
        let model = SettingsViewModel(
            repository: repository, undoModel: undo, reminderService: reminder, biometricService: biometric,
            now: { clock }, timeZone: { zone }
        )

        try model.deleteAllHistory()
        #expect(try repository.entries().isEmpty)
        #expect(try repository.checkIns().isEmpty)

        undo.undo()
        #expect(try repository.entries().count == 1)
        #expect(try repository.checkIns().count == 1)
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
final class TestReminderService: ReminderService {
    struct ScheduledReminder: Equatable {
        let hour: Int
        let minute: Int
        let skipToday: Bool
    }

    var requestedAuthorization = false
    var isAuthorized = false
    var shouldGrant = true
    var scheduledReminder: ScheduledReminder?
    var cancelled = false

    func requestAuthorization() async -> Bool {
        requestedAuthorization = true
        isAuthorized = shouldGrant
        return shouldGrant
    }

    func checkAuthorizationStatus() async -> Bool {
        isAuthorized
    }

    func scheduleDailyReminder(hour: Int, minute: Int, skipToday: Bool) async throws {
        scheduledReminder = ScheduledReminder(hour: hour, minute: minute, skipToday: skipToday)
        cancelled = false
    }

    func cancelDailyReminder() async {
        scheduledReminder = nil
        cancelled = true
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

    func authenticate(reason _: String) async -> Bool {
        didAuthenticate = true
        return shouldSucceed
    }
}
