import Foundation
import Observation

@MainActor
@Observable
final class PatternsViewModel {
    private(set) var state: Loadable<PatternsViewData> = .idle
    private(set) var selectedRange: PatternsRange = .sevenDays
    private(set) var loadTask: Task<Void, Never>?
    private let repository: any DiaryRepository
    private let now: () -> Date
    private let timeZone: () -> TimeZone

    init(repository: any DiaryRepository, now: @escaping () -> Date, timeZone: @escaping () -> TimeZone) {
        self.repository = repository
        self.now = now
        self.timeZone = timeZone
    }

    func selectRange(_ range: PatternsRange) {
        guard range != selectedRange else { return }
        selectedRange = range
        load()
    }

    func load() {
        loadTask?.cancel()
        if case .loaded = state {} else {
            state = .loading
        }
        let range = selectedRange
        loadTask = Task {
            do {
                try Task.checkCancellation()
                let entries = try repository.entries()
                let checkIns = try repository.checkIns()
                try Task.checkCancellation()
                state = try .loaded(Self.viewData(
                    for: entries, checkIns: checkIns, range: range, today: now(), timeZone: timeZone()
                ))
            } catch is CancellationError {
            } catch {
                Log.report(error, context: Log.Context(operation: "patterns.load"))
                state = .failed(AppError(wrapping: error))
            }
        }
    }

    static func viewData(
        for entries: [DiaryEntry], checkIns: [NoPoopCheckIn], range: PatternsRange, today: Date, timeZone: TimeZone
    ) throws -> PatternsViewData {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let todayDay = try DiaryDay(date: today, timeZone: timeZone)
        let days = try (0 ..< range.rawValue).reversed().map { offset in
            try DiaryDay(
                date: calendar.date(byAdding: .day, value: -offset, to: today) ?? today,
                timeZone: timeZone
            )
        }
        guard let firstDay = days.first else { throw AppError.invalidOccurrence }

        let inRangeEntries = entries.filter { entry in
            let day = DiaryDay(occurrence: entry.occurrence)
            return day >= firstDay && day <= todayDay
        }

        let maxCount = max(1, days.map { day in
            inRangeEntries.filter { DiaryDay(occurrence: $0.occurrence) == day }.count
        }.max() ?? 1)

        let context = ActivityContext(
            entries: inRangeEntries, checkIns: checkIns, maxCount: maxCount,
            range: range, calendar: calendar, timeZone: timeZone
        )
        let activity = days.map { day in
            activityViewData(for: day, context: context)
        }

        let rangeLabel = formattedDateRange(firstDay: firstDay, todayDay: todayDay, calendar: calendar)
        let summaryLabel = formattedSummary(count: inRangeEntries.count, range: range)
        let timeOfDay = timeOfDaySection(for: inRangeEntries)
        let consistency = consistencySection(for: inRangeEntries)

        return PatternsViewData(
            range: range,
            totalEntries: inRangeEntries.count,
            dateRangeLabel: rangeLabel,
            summaryLabel: summaryLabel,
            dailyActivity: activity,
            timeOfDay: timeOfDay,
            consistency: consistency
        )
    }

    private struct ActivityContext {
        let entries: [DiaryEntry]
        let checkIns: [NoPoopCheckIn]
        let maxCount: Int
        let range: PatternsRange
        let calendar: Calendar
        let timeZone: TimeZone
    }

    private static func activityViewData(
        for day: DiaryDay, context: ActivityContext
    ) -> PatternsDailyActivityViewData {
        let count = context.entries.filter { DiaryDay(occurrence: $0.occurrence) == day }.count
        let checkIn = context.checkIns.first { $0.day == day }
        let status: PatternsDayStatus
        let statusMark: String

        if count > 0 {
            status = .logged
            statusMark = "\(count)"
        } else if let checkIn, checkIn.coverage == .completed {
            status = .confirmedNoPoop
            statusMark = "0"
        } else if let checkIn, checkIn.coverage == .partial {
            status = .partialCheckIn
            statusMark = "…"
        } else {
            status = .unrecorded
            statusMark = "—"
        }

        let dayDate = context.calendar
            .date(from: DateComponents(timeZone: context.timeZone, year: day.year, month: day.month, day: day.day)) ?? .now
        let label = context.range == .sevenDays ? dayDate.formatted(.dateTime.weekday(.narrow)) : "\(day.day)"
        let dayLong = dayDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        let statusDescription = switch status {
        case .logged: String(localized: "patterns.status.logged \(count)", bundle: .module)
        case .confirmedNoPoop: String(localized: "checkIn.completed", bundle: .module)
        case .partialCheckIn: String(localized: "checkIn.noneSoFar", bundle: .module)
        case .unrecorded: String(localized: "checkIn.unknown", bundle: .module)
        }
        let a11y = "\(dayLong): \(statusDescription)"

        return PatternsDailyActivityViewData(
            dayID: day.id,
            label: label,
            count: count,
            ratio: Double(count) / Double(context.maxCount),
            status: status,
            statusMark: statusMark,
            accessibilityLabel: a11y
        )
    }

    private static func timeOfDaySection(for entries: [DiaryEntry]) -> PatternsTimeOfDaySectionViewData {
        guard !entries.isEmpty else {
            return PatternsTimeOfDaySectionViewData(periods: [], hasEntries: false)
        }
        let total = Double(entries.count)
        let periods: [PatternsTimePeriod] = [.morning, .afternoon, .evening, .night]
        let items = periods.map { period in
            let count = entries.filter { entry in
                let hour = entry.occurrence.hour
                return switch period {
                case .morning: hour >= 5 && hour < 12
                case .afternoon: hour >= 12 && hour < 17
                case .evening: hour >= 17 && hour < 22
                case .night: hour < 5 || hour >= 22
                }
            }.count
            let title = switch period {
            case .morning: String(localized: "patterns.timeOfDay.morning", bundle: .module)
            case .afternoon: String(localized: "patterns.timeOfDay.afternoon", bundle: .module)
            case .evening: String(localized: "patterns.timeOfDay.evening", bundle: .module)
            case .night: String(localized: "patterns.timeOfDay.night", bundle: .module)
            }
            return PatternsPeriodViewData(
                period: period,
                title: title,
                count: count,
                ratio: total > 0 ? Double(count) / total : 0
            )
        }
        return PatternsTimeOfDaySectionViewData(periods: items, hasEntries: true)
    }

    private static func consistencySection(for entries: [DiaryEntry]) -> PatternsConsistencySectionViewData {
        let classified = entries.filter { $0.stoolType != nil }
        guard !classified.isEmpty else {
            return PatternsConsistencySectionViewData(
                items: [], totalClassified: 0, totalEntries: entries.count,
                hasEntries: false, ratioLabel: String(localized: "patterns.consistency.noneClassified", bundle: .module)
            )
        }
        let total = Double(classified.count)
        let items: [PatternsConsistencyItemViewData] = (1 ... 7).compactMap { type in
            let count = classified.filter { $0.stoolType == type }.count
            guard count > 0 else { return nil }
            let title = String(localized: "patterns.consistency.type \(type)", bundle: .module)
            return PatternsConsistencyItemViewData(
                type: type,
                title: title,
                count: count,
                ratio: total > 0 ? Double(count) / total : 0
            )
        }
        let ratioLabel = String(
            localized: "patterns.consistency.classifiedRatio \(classified.count), \(entries.count)",
            bundle: .module
        )
        return PatternsConsistencySectionViewData(
            items: items, totalClassified: classified.count, totalEntries: entries.count,
            hasEntries: true, ratioLabel: ratioLabel
        )
    }

    private static func formattedDateRange(firstDay: DiaryDay, todayDay: DiaryDay, calendar: Calendar) -> String {
        let firstDate = calendar.date(from: DateComponents(year: firstDay.year, month: firstDay.month, day: firstDay.day)) ?? .now
        let todayDate = calendar.date(from: DateComponents(year: todayDay.year, month: todayDay.month, day: todayDay.day)) ?? .now
        let style = Date.FormatStyle.dateTime.month(.abbreviated).day()
        return "\(firstDate.formatted(style)) – \(todayDate.formatted(style))"
    }

    private static func formattedSummary(count: Int, range: PatternsRange) -> String {
        if count == 1 {
            String(localized: "patterns.stat.entryLogged \(range.rawValue)", bundle: .module)
        } else {
            String(localized: "patterns.stat.entriesLogged \(count), \(range.rawValue)", bundle: .module)
        }
    }
}
