import Foundation

struct InsightsContext {
    let source: InsightsSource
    let calendar: Calendar
    let today: DiaryDay
    let marks: DayMarks
    let days: [DiaryDay]
    let previousDays: [DiaryDay]
    let interval: DateInterval

    init(_ source: InsightsSource) throws {
        self.source = source
        calendar = TodayViewModel.calendar(source.timeZone)
        today = try DiaryDay(date: source.now, timeZone: source.timeZone)
        marks = DayMarks(entries: source.entries, checkIns: source.checkIns, today: today)
        let component = source.period.component
        guard let anchor = calendar.date(byAdding: component, value: source.offset, to: source.now),
              let interval = calendar.dateInterval(of: component, for: anchor),
              let previousAnchor = calendar.date(byAdding: component, value: -1, to: interval.start),
              let previous = calendar.dateInterval(of: component, for: previousAnchor)
        else { throw AppError.invalidOccurrence }
        self.interval = interval
        days = try Self.days(in: interval, calendar: calendar)
        previousDays = try Self.days(in: previous, calendar: calendar)
    }

    var logs: [DiaryEntry] {
        days.flatMap { marks.logs[$0] ?? [] }
    }

    var pastLogs: [DiaryEntry] {
        days.filter { $0 <= today }.flatMap { marks.logs[$0] ?? [] }
    }

    var recordedDays: [DiaryDay] {
        days.filter { $0 <= today && InsightsStats.isRecorded(marks.mark($0)) }
    }

    var isSettled: Bool {
        recordedDays.count >= 4
    }

    func date(_ day: DiaryDay) -> Date {
        (try? TodayViewModel.start(of: day, calendar: calendar)) ?? interval.start
    }

    func format(_ date: Date, _ style: Date.FormatStyle) -> String {
        var style = style
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    func span(_ days: [DiaryDay]) -> String {
        guard let first = days.first, let last = days.last else { return "" }
        var style = Date.IntervalFormatStyle().day().month(.abbreviated)
        style.timeZone = calendar.timeZone
        return (date(first) ..< date(last)).formatted(style)
    }

    private static func days(in interval: DateInterval, calendar: Calendar) throws -> [DiaryDay] {
        var days: [DiaryDay] = []
        var date = interval.start
        while date < interval.end {
            try days.append(DiaryDay(date: date, timeZone: calendar.timeZone))
            guard let next = calendar.date(byAdding: .day, value: 1, to: date) else { throw AppError.invalidOccurrence }
            date = next
        }
        return days
    }
}

extension InsightsViewModel {
    nonisolated static func viewData(_ source: InsightsSource) throws -> InsightsViewData {
        let context = try InsightsContext(source)
        let logs = context.logs
        let loggedDays = context.days.count { context.marks.logs[$0] != nil }
        let unrecorded = context.days.filter { context.marks.mark($0) == .unrecorded }
        let header = header(context)
        let baseline = InsightsBaseline(context)
        let doctor = doctorFlags(context)
        let changes = changes(context, baseline: baseline)
        let count = logs.isEmpty ? String(localized: "insights.headline.empty", bundle: .module)
            : String(
                localized: "insights.headline \(TodayViewModel.logCount(logs.count)) \(dayCount(loggedDays))",
                bundle: .module
            )
        let verdict = changes.first?.title ?? baseline.flatMap { _ in context.isSettled ? usualHeadline(source.period) : nil }
        return InsightsViewData(
            period: source.period,
            title: header.title,
            detail: header.detail,
            accessibilityLabel: [header.title, header.detail].compactMap(\.self).joined(separator: " "),
            canMoveNext: source.offset < 0,
            headline: verdict ?? count,
            headlineDetail: verdict == nil ? sinceFirst(context) : count,
            summaryNote: doctorSummary(doctor),
            unrecorded: unrecorded.first.map {
                HistoryUnrecordedViewData(dayID: $0.id, label: unrecordedLabel(unrecorded.count))
            },
            doctor: doctor,
            changes: changes,
            usual: usual(context, baseline: baseline),
            consistency: consistency(context),
            when: when(context),
            comfort: comfort(context, baseline: baseline),
            types: types(logs, context: context),
            frequency: frequency(context, logs: logs.count, loggedDays: loggedDays)
        )
    }

    private nonisolated static func usualHeadline(_ period: InsightsPeriod) -> String {
        switch period {
        case .week: String(localized: "insights.headline.usualWeek", bundle: .module)
        case .month: String(localized: "insights.headline.usualMonth", bundle: .module)
        case .year: String(localized: "insights.headline.usualYear", bundle: .module)
        }
    }

    private nonisolated static func sinceFirst(_ context: InsightsContext) -> String? {
        guard let first = context.marks.firstDay, context.days.contains(first), first != context.days.first else { return nil }
        let date = context.format(context.date(first), .dateTime.day().month(.abbreviated))
        return String(localized: "insights.since \(date)", bundle: .module)
    }

    nonisolated static func dayCount(_ count: Int) -> String {
        count == 1 ? String(localized: "insights.dayCount.one", bundle: .module)
            : String(localized: "insights.dayCount \(count)", bundle: .module)
    }

    nonisolated static func unrecordedLabel(_ count: Int) -> String {
        count == 1 ? String(localized: "history.unrecordedDays.one", bundle: .module)
            : String(localized: "history.unrecordedDays \(count)", bundle: .module)
    }

    nonisolated static func rangeLabel(_ context: InsightsContext) -> String {
        guard let first = context.days.first, let last = context.days.last else { return "" }
        switch context.source.period {
        case .week:
            return context.span([first, last])
        case .month:
            return context.format(context.date(first), .dateTime.month(.wide).year())
        case .year:
            return context.format(context.date(first), .dateTime.year())
        }
    }

    private nonisolated static func header(_ context: InsightsContext) -> (title: String, detail: String?) {
        let start = context.interval.start
        switch context.source.period {
        case .week:
            let title: String? = switch context.source.offset {
            case 0: String(localized: "insights.thisWeek", bundle: .module)
            case -1: String(localized: "insights.lastWeek", bundle: .module)
            default: nil
            }
            return title.map { ($0, rangeLabel(context)) } ?? (rangeLabel(context), nil)
        case .month:
            return (context.format(start, .dateTime.month(.wide)), context.format(start, .dateTime.year()))
        case .year:
            return (context.format(start, .dateTime.year()), nil)
        }
    }

    private nonisolated static func types(_ logs: [DiaryEntry], context: InsightsContext) -> [InsightsTypeViewData] {
        let grouped = Dictionary(grouping: logs.filter { $0.stoolType != nil }) { $0.stoolType ?? 0 }
        return grouped.sorted { ($0.value.count, -$0.key) > ($1.value.count, -$1.key) }.compactMap { type, entries in
            guard let choice = EntryChoiceViewData.types.first(where: { $0.id == String(type) }) else { return nil }
            let days = Set(entries.map { DiaryDay(occurrence: $0.occurrence) }).sorted()
            let daysLabel = context.source.period == .week
                ? days.map { context.format(context.date($0), .dateTime.weekday(.abbreviated)) }.joined(separator: ", ")
                : dayCount(days.count)
            return InsightsTypeViewData(
                id: type, title: choice.title + " · " + choice.detail, illustration: choice.illustration,
                days: daysLabel, count: TodayViewModel.logCount(entries.count)
            )
        }
    }
}
