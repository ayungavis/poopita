import Foundation

extension PatternsViewModel {
    static func viewData(
        for entries: [DiaryEntry], checkIns: [NoPoopCheckIn], range: PatternsRange, today: Date, timeZone: TimeZone
    ) throws -> PatternsViewData {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let days = try days(in: range, today: today, calendar: calendar, timeZone: timeZone)
        guard let firstDay = days.first, let todayDay = days.last else { throw AppError.invalidOccurrence }
        let inRangeEntries = entries.filter {
            let day = DiaryDay(occurrence: $0.occurrence)
            return day >= firstDay && day <= todayDay
        }
        let entriesByDay = Dictionary(grouping: inRangeEntries) { DiaryDay(occurrence: $0.occurrence) }
        let checkInsByDay = Dictionary(grouping: checkIns, by: \.day)
        let maxCount = max(1, entriesByDay.values.map(\.count).max() ?? 0)
        let context = ActivityContext(maxCount: maxCount, range: range, calendar: calendar)
        let activity = days.map { day in
            dailyActivity(
                for: day, count: entriesByDay[day]?.count ?? 0,
                coverage: checkInsByDay[day]?.first?.coverage, context: context
            )
        }
        return PatternsViewData(
            range: range,
            totalEntries: inRangeEntries.count,
            dateRangeLabel: formattedDateRange(firstDay: firstDay, todayDay: todayDay, calendar: calendar, range: range),
            summaryLabel: formattedSummary(count: inRangeEntries.count, range: range),
            coverage: coverageSummary(activity),
            dailyActivity: activity,
            dayDetails: days.map { day in
                dayDetail(
                    for: day, entries: entriesByDay[day] ?? [],
                    coverage: checkInsByDay[day]?.first?.coverage, calendar: calendar
                )
            },
            timeOfDay: timeOfDay(for: inRangeEntries),
            consistency: consistency(for: inRangeEntries),
            activityBuckets: activityBuckets(for: activity, days: days, range: range, calendar: calendar),
            timeline: inRangeEntries.sorted { $0.occurrence.instant < $1.occurrence.instant }.map {
                PatternsTimelinePointViewData(
                    id: $0.id, hour: Double($0.occurrence.hour) + Double($0.occurrence.minute) / 60,
                    timeLabel: timeLabel(for: $0.occurrence)
                )
            },
            amount: observationSection(
                choices: EntryChoiceViewData.amounts, values: inRangeEntries.compactMap { $0.amount?.rawValue },
                totalEntries: inRangeEntries.count
            ),
            effort: observationSection(
                choices: EntryChoiceViewData.efforts, values: inRangeEntries.compactMap { $0.effort?.rawValue },
                totalEntries: inRangeEntries.count
            )
        )
    }

    private static func days(
        in range: PatternsRange, today: Date, calendar: Calendar, timeZone: TimeZone
    ) throws -> [DiaryDay] {
        let end = calendar.startOfDay(for: today)
        let start: Date? = if range == .oneYear {
            calendar.date(byAdding: .year, value: -1, to: end)
        } else if let count = range.dayCount {
            calendar.date(byAdding: .day, value: 1 - count, to: end)
        } else {
            nil
        }
        guard let start, let count = calendar.dateComponents([.day], from: start, to: end).day else {
            throw AppError.invalidOccurrence
        }
        return try (0 ... count).map { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else {
                throw AppError.invalidOccurrence
            }
            return try DiaryDay(date: date, timeZone: timeZone)
        }
    }

    static func coverageSummary(_ activity: [PatternsDailyActivityViewData]) -> PatternsCoverageViewData {
        PatternsCoverageViewData(
            loggedDays: activity.filter { $0.status == .logged }.count,
            confirmedNoPoopDays: activity.filter { $0.status == .confirmedNoPoop }.count,
            partialDays: activity.filter { $0.status == .partialCheckIn }.count,
            unrecordedDays: activity.filter { $0.status == .unrecorded }.count
        )
    }

    static func date(for day: DiaryDay, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: day.year, month: day.month, day: day.day)) ?? .distantPast
    }

    static func formatted(_ date: Date, style: Date.FormatStyle, calendar: Calendar) -> String {
        var style = style
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    private static func formattedDateRange(
        firstDay: DiaryDay, todayDay: DiaryDay, calendar: Calendar, range: PatternsRange
    ) -> String {
        let first = date(for: firstDay, calendar: calendar)
        let today = date(for: todayDay, calendar: calendar)
        if range == .oneDay {
            return formatted(today, style: .dateTime.weekday(.wide).month(.wide).day().year(), calendar: calendar)
        }
        let style: Date.FormatStyle = range == .oneYear
            ? .dateTime.month(.abbreviated).year() : .dateTime.month(.abbreviated).day()
        return "\(formatted(first, style: style, calendar: calendar)) – \(formatted(today, style: style, calendar: calendar))"
    }

    private static func formattedSummary(count: Int, range: PatternsRange) -> String {
        let title = String(localized: String.LocalizationValue(range.displayKey), bundle: .module)
        return String(localized: "patterns.stat.summary \(count), \(title)", bundle: .module)
    }
}
