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
            Self.on { _ in }, context: ReminderPlanner.Context(loggedDays: [today], lastActivity: nil), now: Self.now,
            calendar: Self.calendar
        )
        #expect(plan.count == ReminderPlanner.horizonDays - 1)
        #expect(plan.allSatisfy { $0.kind == .daily && $0.date > Self.now })
        #expect(plan.allSatisfy { Self.calendar.component(.hour, from: $0.date) == 20 })

        let notSkipping = ReminderPlanner.plan(
            Self.on { $0.skipsLoggedDays = false }, context: ReminderPlanner.Context(loggedDays: [today], lastActivity: nil),
            now: Self.now, calendar: Self.calendar
        )
        #expect(notSkipping.count == ReminderPlanner.horizonDays)
    }

    @Test func respectsChosenDaysTheWeeklySummaryAndTheGapAlert() {
        let weekends = ReminderPlanner.plan(
            Self.on { $0.weekdays = [1, 7] }, context: ReminderPlanner.Context(loggedDays: [], lastActivity: nil), now: Self.now,
            calendar: Self.calendar
        )
        #expect(weekends.allSatisfy { [1, 7].contains(Self.calendar.component(.weekday, from: $0.date)) })

        let extras = ReminderPlanner.plan(
            Self.on {
                $0.isEnabled = false
                $0.sendsWeeklySummary = true
                $0.alertsAfterGap = true
            },
            context: ReminderPlanner.Context(loggedDays: [], lastActivity: Self.now), now: Self.now, calendar: Self.calendar
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

    @Test func mapsNotificationActionsAndOffersSnoozeOnlyWhileItFits() {
        #expect(ReminderCategory.response(action: ReminderCategory.noneSoFar, category: ReminderCategory.daily) == .noneSoFar)
        #expect(
            ReminderCategory.response(action: ReminderCategory.defaultAction, category: ReminderCategory.weeklySummary)
                == .opened(.weeklySummary)
        )
        #expect(ReminderCategory.response(action: "unknown", category: ReminderCategory.daily) == nil)

        let at = { (hour: Int, minute: Int) in
            Self.calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Self.now) ?? Self.now
        }
        #expect(ReminderPlanner.canSnooze(after: at(21, 0), count: 1, calendar: Self.calendar))
        #expect(!ReminderPlanner.canSnooze(after: at(21, 0), count: 2, calendar: Self.calendar))
        #expect(!ReminderPlanner.canSnooze(after: at(22, 30), count: 0, calendar: Self.calendar))
        #expect(ReminderCategory.identifier(for: PlannedReminder(kind: .daily, date: at(22, 30))) == ReminderCategory
            .dailyLastCall)

        let late = ReminderPlanner.plan(
            Self.on {
                $0.hour = 22
                $0.minute = 30
            },
            context: ReminderPlanner.Context(), now: Self.now, calendar: Self.calendar
        )
        #expect(late.allSatisfy { !$0.allowsSnooze })
    }

    @Test func noneSoFarSavesAPartialCheckInAndDropsTodaysReminder() async throws {
        let fixture = try Self.model()
        fixture.model.setEnabled(true)
        #expect(fixture.model.plan().first.map { Self.calendar.isDate($0.date, inSameDayAs: Self.now) } == true)

        await fixture.model.handle(.noneSoFar)
        let checkIn = try #require(try fixture.diary.checkIns().first)
        #expect(checkIn.coverage == .partial)
        #expect(fixture.model.revision == 1)
        #expect(fixture.model.plan().allSatisfy { $0.kind != .daily || !Self.calendar.isDate($0.date, inSameDayAs: Self.now) })
    }

    @Test func snoozeAddsOneHourAtMostTwiceADay() async throws {
        let fixture = try Self.model()
        await fixture.model.handle(.snooze)
        await fixture.model.handle(.snooze)
        await fixture.model.handle(.snooze)
        let snooze = try #require(fixture.repository.snooze())
        #expect(snooze.count == 2)
        #expect(snooze.until == Self.now.addingTimeInterval(3600))
        let planned = fixture.model.plan().first { $0.date == Self.now.addingTimeInterval(3600) }
        #expect(planned?.allowsSnooze == false)
    }

    @Test func tappingRoutesToLogOrInsights() async throws {
        let fixture = try Self.model()
        await fixture.model.handle(.opened(.weeklySummary))
        #expect(fixture.model.route == .insights)
        fixture.model.consumeRoute()
        await fixture.model.handle(.logNow)
        #expect(fixture.model.route == .log)
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
        return RemindersFixture(model: model, service: service, repository: repository, diary: diary)
    }
}

@MainActor
struct RemindersFixture {
    let model: RemindersViewModel
    let service: TestReminderService
    let repository: LocalReminderRepository
    let diary: LocalDiaryRepository
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
