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

    func date(_ day: DiaryDay) -> Date {
        (try? TodayViewModel.start(of: day, calendar: calendar)) ?? interval.start
    }

    func format(_ date: Date, _ style: Date.FormatStyle) -> String {
        var style = style
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    func hasUnrecorded(_ days: [DiaryDay]) -> Bool {
        days.contains { marks.mark($0) == .unrecorded }
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
        return InsightsViewData(
            period: source.period,
            title: header.title,
            detail: header.detail,
            accessibilityLabel: [header.title, header.detail].compactMap(\.self).joined(separator: " "),
            canMoveNext: source.offset < 0,
            headline: logs.isEmpty ? String(localized: "insights.headline.empty", bundle: .module)
                : String(localized: "insights.headline \(TodayViewModel.logCount(logs.count)) \(dayCount(loggedDays))",
                         bundle: .module),
            usual: usual(logs, context: context),
            comparison: comparison(context, count: logs.count),
            unrecorded: unrecorded.first.map {
                HistoryUnrecordedViewData(dayID: $0.id, label: unrecordedLabel(unrecorded.count))
            },
            when: when(context),
            types: types(logs, context: context),
            frequency: frequency(context, logs: logs.count, loggedDays: loggedDays)
        )
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
            let style = Date.FormatStyle.dateTime.day().month(.abbreviated)
            return context.format(context.date(first), style) + " – " + context.format(context.date(last), style)
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

    private nonisolated static func usual(_ logs: [DiaryEntry], context: InsightsContext) -> String? {
        var parts: [String] = []
        let hours = logs.map(\.occurrence.hour)
        if hours.count >= 3 {
            let best = Set(hours).sorted().max { start, other in
                hours.count { (start ..< start + 3).contains($0) } < hours.count { (other ..< other + 3).contains($0) }
            } ?? 0
            if hours.count(where: { (best ..< best + 3).contains($0) }) * 2 > hours.count {
                parts.append(String(
                    localized: "insights.usual \(hourLabel(best, context)) \(hourLabel(best + 3, context))",
                    bundle: .module
                ))
            }
        }
        if let choice = mostlyType(logs) {
            parts.append(parts.isEmpty ? String(localized: "insights.mostlyStart \(choice.title)", bundle: .module)
                : String(localized: "insights.mostly \(choice.title)", bundle: .module))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private nonisolated static func mostlyType(_ logs: [DiaryEntry]) -> EntryChoiceViewData? {
        let ranked = Dictionary(grouping: logs.compactMap(\.stoolType)) { $0 }.mapValues(\.count)
            .sorted { $0.value > $1.value }
        guard let top = ranked.first, top.value * 2 > ranked.reduce(0, { $0 + $1.value }),
              top.value > ranked.dropFirst().first?.value ?? 0
        else { return nil }
        return EntryChoiceViewData.types.first { $0.id == String(top.key) }
    }

    private nonisolated static func hourLabel(_ hour: Int, _ context: InsightsContext) -> String {
        clock(hour * 60, .dateTime.hour().minute(), context)
    }

    private nonisolated static func comparison(_ context: InsightsContext, count: Int) -> String? {
        guard !context.hasUnrecorded(context.days), !context.hasUnrecorded(context.previousDays) else { return nil }
        let previous = context.previousDays.reduce(0) { $0 + (context.marks.logs[$1]?.count ?? 0) }
        let unit = previousName(context.source)
        let difference = count - previous
        if difference == 0 {
            return String(localized: "insights.same \(unit)", bundle: .module)
        }
        return difference < 0 ? String(localized: "insights.fewer \(-difference) \(unit)", bundle: .module)
            : String(localized: "insights.more \(difference) \(unit)", bundle: .module)
    }

    private nonisolated static func previousName(_ source: InsightsSource) -> String {
        let isCurrent = source.offset == 0
        return switch source.period {
        case .week: String(localized: isCurrent ? "insights.previous.lastWeek" : "insights.previous.week", bundle: .module)
        case .month: String(localized: isCurrent ? "insights.previous.lastMonth" : "insights.previous.month", bundle: .module)
        case .year: String(localized: isCurrent ? "insights.previous.lastYear" : "insights.previous.year", bundle: .module)
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
