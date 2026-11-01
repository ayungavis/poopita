import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct InsightsFlowTests {
    private let zone = TimeZone(secondsFromGMT: 0) ?? .gmt

    @Test func weekSummarisesLogsWithoutCountingUnknownDays() throws {
        let data = try InsightsViewModel.viewData(source(figmaWeek(), checkIns: figmaCheckIns(), period: .week))
        #expect(data.title == "This week")
        #expect(!data.canMoveNext)
        #expect(data.headline == "5 logs on 3 days")
        #expect(data.headlineDetail == nil)
        #expect(data.usual.rows.isEmpty)
        #expect(data.usual.note == "Log a few more days to see your usual.")
        #expect(data.summaryNote == nil)
        #expect(data.doctor.isEmpty)
        #expect(data.changes.isEmpty)
        #expect(data.consistency.rows.count == 4)
        #expect(data.consistency.lead == "0 hard and 0 loose of 5 logs, all under the 25% line.")
        #expect(data.unrecorded == HistoryUnrecordedViewData(dayID: "2026-10-29", label: "1 day not recorded"))
        #expect(data.types.map(\.id) == [4, 3])
        #expect(data.types.first?.days == "Mon, Tue, Sat")
        #expect(data.types.first?.count == "3 logs")

        let when = data.when
        #expect(when.columns.count == 7)
        #expect(when.startMinute == 300)
        #expect(when.endMinute == 1320)
        #expect(when.columns[3].isUnrecorded)
        #expect(when.columns[4].checkInMinute == 20 * 60 + 10)
        #expect(when.columns[5].nowMinute == 9 * 60 + 41)
        #expect(when.columns[1].logMinutes == [7 * 60 + 20, 21 * 60 + 5])

        let frequency = data.frequency
        #expect(frequency.average == 1.7.formatted(.number.precision(.fractionLength(0 ... 1))))
        #expect(frequency.basis.hasPrefix("5 logs on 3 logged days · "))
        #expect(frequency.bars[3].isUnrecorded)
        #expect(frequency.bars[1].ratio == 1)
        #expect(frequency.breakdownTitle == "This week's 7 days")
        #expect(frequency.breakdown.map(\.count) == ["3", "1", "1", "1", "1"])
    }

    @Test func aChangeFromYourUsualLeadsAndRedFlagsAreSummarised() throws {
        let usualDays = try (1 ... 28).map { offset in
            try entry(date: date("2026-10-26T07:00:00Z").addingTimeInterval(Double(-offset) * 86400), type: 4)
        }
        let looser = try (26 ... 30).map { try entry(day: $0, hour: 13, type: 6) }
        let base = try entry(day: 31, hour: 7, minute: 20, type: 6)
        let bloody = DiaryEntry(
            id: base.id, occurrence: base.occurrence, stoolType: 6, amount: nil, effort: nil, blood: .seen, note: ""
        )
        let data = try InsightsViewModel.viewData(source(usualDays + looser + [bloody], checkIns: [], period: .week))
        #expect(data.headline == "Looser than usual")
        #expect(data.headlineDetail == "6 logs on 6 days")
        #expect(data.changes.map(\.id) == ["looser", "timing"])
        #expect(data.changes.first?.dayID == "2026-10-26")
        #expect(data.doctor.map(\.id) == ["blood"])
        var style = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated)
        style.timeZone = zone
        let saturday = try "Blood seen on " + date("2026-10-31T07:20:00Z").formatted(style)
        #expect(data.doctor.first?.title == saturday)
        let twice = try InsightsViewModel.viewData(source(usualDays + looser + [bloody, DiaryEntry(
            id: UUID(), occurrence: bloody.occurrence, stoolType: 6, amount: nil, effort: nil, blood: .seen, note: ""
        )], checkIns: [], period: .week))
        #expect(twice.doctor.first?.title == saturday)
        #expect(data.summaryNote == "Blood seen · worth a doctor's look")
        #expect(data.usual.rows.map(\.id) == ["often", "type", "time"])
        #expect(data.usual.rows[1].value == "Mostly 6 · usual 4")
        #expect(data.consistency.lead == "6 of 6 logs were loose (100%), past the 25% line.")
        #expect(data.consistency.rows.last?.loose == 1)
    }

    @Test func aWeekLikeYourUsualSaysSoWithoutFlags() throws {
        let usualDays = try (1 ... 28).map { offset in
            try entry(date: date("2026-10-26T07:00:00Z").addingTimeInterval(Double(-offset) * 86400), type: 4)
        }
        let week = try (26 ... 31).map { try entry(day: $0, hour: 7, type: 4) }
        let data = try InsightsViewModel.viewData(source(usualDays + week, checkIns: [], period: .week))
        #expect(data.headline == "A usual week")
        #expect(data.changes.isEmpty)
        #expect(data.doctor.isEmpty)
        #expect(data.usual.note == "Compared with your last 28 recorded days.")
        #expect(data.usual.rows.first?.value == "1 a day · usual 1")

        let fresh = try InsightsViewModel.viewData(source(
            usualDays + week,
            checkIns: [],
            period: .week,
            now: date("2026-11-02T00:30:00Z")
        ))
        #expect(fresh.headline == "No logs yet")

        let oneHardDay = try (0 ..< 6).map { try entry(day: 1, month: 11, hour: 8 + $0, type: 1) }
        let thin = try InsightsViewModel.viewData(source(
            usualDays + week + oneHardDay, checkIns: [], period: .month, now: date("2026-11-02T00:30:00Z")
        ))
        #expect(thin.changes.isEmpty)
        #expect(thin.headline == "6 logs on 1 day")
        var span = Date.IntervalFormatStyle().day().month(.abbreviated)
        span.timeZone = zone
        #expect(try fresh.consistency.rows[2].label == (date("2026-10-26T00:00:00Z") ..< date("2026-11-01T00:00:00Z"))
            .formatted(span))
        #expect(try fresh.consistency.rows[2].label.contains(date("2026-10-26T00:00:00Z").formatted(
            Date.FormatStyle(timeZone: zone).month(.abbreviated)
        )))
    }

    @Test func monthAndYearGroupTheSameChartsByWeekAndMonth() throws {
        let month = try InsightsViewModel.viewData(source(figmaWeek(), checkIns: figmaCheckIns(), period: .month))
        #expect(month.title == "October")
        #expect(month.when.columns.count == 31)
        #expect(month.when.columns.allSatisfy { $0.cell == nil })
        #expect(month.frequency.bars.count == 5)
        #expect(month.frequency.breakdownTitle == "This month's 31 days")
        #expect(month.consistency.rows.count == 5)
        #expect(month.when.columns[27].isConfirmedNone)

        let year = try InsightsViewModel.viewData(source(figmaWeek(), checkIns: figmaCheckIns(), period: .year))
        #expect(year.title == "2026")
        #expect(year.when.columns.count == 3)
        #expect(year.frequency.bars.count == 12)
        #expect(year.when.columns[0].logMinutes.count == 5)
        #expect(year.when.columns[0].unknownCount == 1)
        #expect(year.when.columns[2].isUnrecorded == false)
        #expect(year.when.isAggregated)
        #expect(year.usual.rows.isEmpty)
        #expect(year.consistency.rows.map(\.label) == ["Oct so far"])
        #expect(year.unrecorded?.dayID == "2026-10-29")
        #expect(year.frequency.breakdown.last?.id == "untracked")
    }

    @Test func viewModelStepsBackButNeverPastTheCurrentPeriod() async throws {
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: fixture()))
        let now = try date("2026-10-31T09:41:00Z")
        let model = InsightsViewModel(repository: repository, now: { now }, timeZone: { zone })
        model.load()
        await model.loadTask?.value
        #expect(Self.loaded(model.state)?.title == "This week")
        model.move(1)
        #expect(model.offset == 0)
        model.move(-1)
        await model.loadTask?.value
        #expect(Self.loaded(model.state)?.title == "Last week")
        #expect(Self.loaded(model.state)?.canMoveNext == true)
        model.select(.month)
        await model.loadTask?.value
        #expect(model.offset == 0)
        #expect(Self.loaded(model.state)?.title == "October")
    }

    private var sundayNight: Date {
        (try? date("2026-11-01T23:00:00Z")) ?? .now
    }

    private func source(
        _ entries: [DiaryEntry], checkIns: [NoPoopCheckIn], period: InsightsPeriod, now: Date? = nil
    ) throws -> InsightsSource {
        try InsightsSource(
            entries: entries, checkIns: checkIns, period: period, offset: 0,
            now: now ?? date("2026-10-31T09:41:00Z"), timeZone: zone
        )
    }

    private func figmaWeek() throws -> [DiaryEntry] {
        try [
            entry(day: 26, hour: 7, type: 4),
            entry(day: 27, hour: 7, minute: 20, type: 4),
            entry(day: 27, hour: 21, minute: 5, type: 3),
            entry(day: 31, hour: 6, minute: 30, type: 4),
            entry(day: 31, hour: 7, minute: 10, type: 3),
        ]
    }

    private func figmaCheckIns() throws -> [NoPoopCheckIn] {
        try [
            NoPoopCheckIn(day: DiaryDay(year: 2026, month: 10, day: 28),
                          reportedAt: occurrence("2026-10-29T08:00:00Z"), coverage: .completed),
            NoPoopCheckIn(day: DiaryDay(year: 2026, month: 10, day: 30),
                          reportedAt: occurrence("2026-10-30T20:10:00Z"), coverage: .partial),
        ]
    }

    private func entry(date: Date, type: Int) throws -> DiaryEntry {
        try DiaryEntry(
            id: UUID(), occurrence: OccurrenceTime(instant: date, timeZone: zone), stoolType: type, amount: nil, effort: nil,
            note: ""
        )
    }

    private func entry(day: Int, month: Int = 10, hour: Int, minute: Int = 0, type: Int) throws -> DiaryEntry {
        let value = String(format: "2026-%02d-%02dT%02d:%02d:00Z", month, day, hour, minute)
        return try DiaryEntry(id: UUID(), occurrence: occurrence(value), stoolType: type, amount: nil, effort: nil, note: "")
    }

    private func occurrence(_ value: String) throws -> OccurrenceTime {
        try OccurrenceTime(instant: date(value), timeZone: zone)
    }

    private func date(_ value: String) throws -> Date {
        guard let date = ISO8601DateFormatter().date(from: value) else { throw AppError.invalidOccurrence }
        return date
    }

    private func clock(_ time: String) throws -> String {
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.timeZone = zone
        return try date("2026-10-26T\(time):00Z").formatted(style)
    }

    private func fixture() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    }

    private static func loaded(_ state: Loadable<InsightsViewData>) -> InsightsViewData? {
        guard case let .loaded(data) = state else { return nil }
        return data
    }
}
