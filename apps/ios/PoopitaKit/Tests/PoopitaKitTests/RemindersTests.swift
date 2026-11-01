import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct RemindersTests {
    private static let zone = TimeZone(identifier: "Asia/Jakarta") ?? .gmt
    private static let now = Date(timeIntervalSince1970: 1_793_511_000)

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }

    private static func on(_ preferences: (inout ReminderPreferences) -> Void) -> ReminderPreferences {
        var value = ReminderPreferences()
        value.isEnabled = true
        value.sendsWeeklySummary = false
        preferences(&value)
        return value
    }

    @Test func plansADailyReminderForTheComingTwoWeeksAndSkipsALoggedToday() {
        let today = DiaryDay(year: 2026, month: 11, day: 1)
        let plan = ReminderPlanner.plan(
            Self.on { _ in }, loggedDays: [today], lastActivity: nil, now: Self.now, calendar: Self.calendar
        )
        #expect(plan.count == ReminderPlanner.horizonDays - 1)
        #expect(plan.allSatisfy { $0.kind == .daily && $0.date > Self.now })
        #expect(plan.allSatisfy { Self.calendar.component(.hour, from: $0.date) == 20 })

        let notSkipping = ReminderPlanner.plan(
            Self.on { $0.skipsLoggedDays = false }, loggedDays: [today], lastActivity: nil,
            now: Self.now, calendar: Self.calendar
        )
        #expect(notSkipping.count == ReminderPlanner.horizonDays)
    }

    @Test func respectsChosenDaysTheWeeklySummaryAndTheGapAlert() {
        let weekends = ReminderPlanner.plan(
            Self.on { $0.weekdays = [1, 7] }, loggedDays: [], lastActivity: nil, now: Self.now, calendar: Self.calendar
        )
        #expect(weekends.allSatisfy { [1, 7].contains(Self.calendar.component(.weekday, from: $0.date)) })

        let extras = ReminderPlanner.plan(
            Self.on {
                $0.isEnabled = false
                $0.sendsWeeklySummary = true
                $0.alertsAfterGap = true
            },
            loggedDays: [], lastActivity: Self.now, now: Self.now, calendar: Self.calendar
        )
        let summaries = extras.filter { $0.kind == .weeklySummary }
        #expect(summaries.count == 2)
        #expect(summaries.allSatisfy { Self.calendar.component(.weekday, from: $0.date) == 1 })
        let gap = extras.first { $0.kind == .gap }
        #expect(gap.map { Self.calendar.dateComponents([.day, .hour], from: $0.date) } == DateComponents(day: 4, hour: 20))
    }

    @Test func preferencesAreSavedAndDrawnAsASettingsSummary() throws {
        let fixture = try Self.model()
        let (model, service, repository) = (fixture.model, fixture.service, fixture.repository)
        #expect(model.state.summary == String(localized: "reminders.off", bundle: .module))

        model.setEnabled(true)
        model.toggleDay(1)
        model.toggleDay(7)
        let weekdays = String(localized: "reminders.weekdays", bundle: .module)
        #expect(model.state.daysLabel == weekdays)
        #expect(model.state.summary.hasSuffix(", " + weekdays.lowercased()))
        #expect(repository.preferences().isEnabled)
        #expect(repository.preferences().weekdays == Set(2 ... 6))
        #expect(service.replaced == nil)

        for day in 2 ... 6 {
            model.toggleDay(day)
        }
        #expect(repository.preferences().weekdays == [6])
    }

    @Test func schedulesOnlyOnceNotificationsAreAllowed() async throws {
        let fixture = try Self.model()
        let (model, service) = (fixture.model, fixture.service)
        model.setEnabled(true)
        await model.scheduleTask?.value
        #expect(model.state.permission == .notAsked)
        #expect(service.replaced == nil)

        await model.requestPermission()
        #expect(model.state.permission == .allowed)
        await model.scheduleTask?.value
        #expect(service.replaced?.contains { $0.kind == .daily } == true)
    }

    private static func model() throws -> RemindersFixture {
        let suite = "RemindersTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let repository = LocalReminderRepository(store: UserDefaultsValueStore(defaults: defaults))
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let diary = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let service = TestReminderService()
        let model = RemindersViewModel(
            repository: repository, diary: diary, service: service, now: { now }, timeZone: { zone }
        )
        return RemindersFixture(model: model, service: service, repository: repository)
    }
}

@MainActor
struct RemindersFixture {
    let model: RemindersViewModel
    let service: TestReminderService
    let repository: LocalReminderRepository
}

@MainActor
final class TestReminderService: ReminderService {
    var current = ReminderPermission.notAsked
    private(set) var replaced: [PlannedReminder]?

    func permission() async -> ReminderPermission {
        current
    }

    func requestPermission() async -> Bool {
        current = .allowed
        return true
    }

    func replace(with reminders: [PlannedReminder]) async throws {
        replaced = reminders
    }
}
