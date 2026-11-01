import Foundation

extension InsightsViewModel {
    nonisolated static func when(_ context: InsightsContext) -> InsightsWhenViewData {
        let columns = context.source.period == .year
            ? monthGroups(context).map { yearColumn($0, context: context) }
            : context.days.map { dayColumn($0, context: context) }
        let minutes = columns.flatMap { $0.logMinutes + [$0.checkInMinute].compactMap(\.self) }
        let start = min(5 * 60, (minutes.min() ?? 5 * 60) / 60 * 60)
        let end = min(24 * 60, max(22 * 60, ((minutes.max() ?? 0) / 60 + 1) * 60))
        let marks = stride(from: 0, through: 24, by: 6).map { $0 * 60 }.filter { $0 > start && $0 < end }.map {
            InsightsHourMarkViewData(minute: $0, label: clock($0, .dateTime.hour(.twoDigits(amPM: .omitted)), context))
        }
        return InsightsWhenViewData(
            startMinute: start, endMinute: end, hourMarks: marks, columns: columns,
            isAggregated: context.source.period == .year
        )
    }

    nonisolated static func frequency(_ context: InsightsContext, logs: Int, loggedDays: Int) -> InsightsFrequencyViewData {
        let groups: [[DiaryDay]] = switch context.source.period {
        case .week: context.days.map { [$0] }
        case .month: weekGroups(context)
        case .year: monthGroups(context)
        }
        let counts = groups.map { $0.reduce(0) { $0 + (context.marks.logs[$1]?.count ?? 0) } }
        let maxCount = max(1, counts.max() ?? 0)
        let bars = zip(groups, counts).map { group, count in
            InsightsBarViewData(
                id: group.first?.id ?? "", cell: context.source.period == .week ? group.first.map { cell($0, context) } : nil,
                label: barLabel(group, context: context), ratio: Double(count) / Double(maxCount),
                isUnrecorded: isUnrecorded(group, context: context),
                summary: groupName(group, context: context) + " · "
                    +
                    (context.source.period == .week && count == 0 ? status(group.first, context) : TodayViewModel
                        .logCount(count))
            )
        }
        let average = loggedDays == 0 ? "–"
            : (Double(logs) / Double(loggedDays)).formatted(.number.precision(.fractionLength(0 ... 1)))
        return InsightsFrequencyViewData(
            average: average,
            basis: String(
                localized: "insights.basis \(TodayViewModel.logCount(logs)) \(loggedDayCount(loggedDays)) \(rangeLabel(context))",
                bundle: .module
            ),
            bars: bars,
            breakdownTitle: breakdownTitle(context),
            breakdown: breakdown(context)
        )
    }

    private nonisolated static func dayColumn(_ day: DiaryDay, context: InsightsContext) -> InsightsColumnViewData {
        let mark = context.marks.mark(day)
        let logs = (context.marks.logs[day] ?? []).sorted { $0.occurrence.instant < $1.occurrence.instant }
        let checkIn = context.marks.checkIns[day]
        let nowParts = context.calendar.dateComponents([.hour, .minute], from: context.source.now)
        let times = logs.map { clock($0.occurrence.hour * 60 + $0.occurrence.minute, .dateTime.hour().minute(), context) }
            .joined(separator: ", ")
        return InsightsColumnViewData(
            id: day.id,
            cell: context.source.period == .week ? cell(day, context) : nil,
            label: context.source.period == .month && day.day % 7 == 1 ? String(day.day) : nil,
            logMinutes: logs.map { $0.occurrence.hour * 60 + $0.occurrence.minute },
            checkInMinute: checkIn?.coverage == .partial ? checkIn.map { $0.reportedAt.hour * 60 + $0.reportedAt.minute } : nil,
            nowMinute: day == context.today ? (nowParts.hour ?? 0) * 60 + (nowParts.minute ?? 0) : nil,
            isUnrecorded: mark == .unrecorded,
            isToday: day == context.today,
            summary: groupName([day], context: context) + " · " + (logs.isEmpty ? status(day, context) : times)
        )
    }

    private nonisolated static func yearColumn(_ days: [DiaryDay], context: InsightsContext) -> InsightsColumnViewData {
        let logs = days.flatMap { context.marks.logs[$0] ?? [] }
        return InsightsColumnViewData(
            id: days.first?.id ?? "",
            cell: nil,
            label: barLabel(days, context: context),
            logMinutes: logs.map { $0.occurrence.hour * 60 + $0.occurrence.minute },
            checkInMinute: nil,
            nowMinute: nil,
            isUnrecorded: isUnrecorded(days, context: context),
            isToday: days.contains(context.today),
            summary: groupName(days, context: context) + " · " + TodayViewModel.logCount(logs.count)
        )
    }

    nonisolated static func cell(_ day: DiaryDay, _ context: InsightsContext) -> InsightsDayCellViewData {
        InsightsDayCellViewData(
            weekday: context.format(context.date(day), .dateTime.weekday(.narrow)), number: String(day.day),
            mark: context.marks.mark(day), isToday: day == context.today
        )
    }

    private nonisolated static func status(_ day: DiaryDay?, _ context: InsightsContext) -> String {
        switch day.map(context.marks.mark) {
        case .noPoop: String(localized: "checkIn.completed", bundle: .module)
        case .noneSoFar: String(localized: "checkIn.partial", bundle: .module)
        case .unrecorded: String(localized: "checkIn.unknown", bundle: .module)
        default: String(localized: "insights.noLogs", bundle: .module)
        }
    }

    private nonisolated static func isUnrecorded(_ days: [DiaryDay], context: InsightsContext) -> Bool {
        let past = days.filter { $0 <= context.today }
        return !past.isEmpty && past.allSatisfy { context.marks.mark($0) == .unrecorded }
    }

    private nonisolated static func groupName(_ days: [DiaryDay], context: InsightsContext) -> String {
        guard let first = days.first, let last = days.last else { return "" }
        if days.count == 1 {
            return context.format(context.date(first), .dateTime.weekday(.abbreviated).day())
        }
        if context.source.period == .year {
            return context.format(context.date(first), .dateTime.month(.abbreviated))
        }
        return context.format(context.date(first), .dateTime.day()) + " – "
            + context.format(context.date(last), .dateTime.day().month(.abbreviated))
    }

    private nonisolated static func barLabel(_ days: [DiaryDay], context: InsightsContext) -> String? {
        guard let first = days.first else { return nil }
        return switch context.source.period {
        case .week: nil
        case .month: String(first.day)
        case .year: context.format(context.date(first), .dateTime.month(.narrow))
        }
    }

    private nonisolated static func weekGroups(_ context: InsightsContext) -> [[DiaryDay]] {
        var groups: [[DiaryDay]] = []
        for day in context.days {
            if let last = groups.last?.last, isSameWeek(last, day, context) {
                groups[groups.count - 1].append(day)
            } else {
                groups.append([day])
            }
        }
        return groups
    }

    private nonisolated static func isSameWeek(_ day: DiaryDay, _ other: DiaryDay, _ context: InsightsContext) -> Bool {
        context.calendar.isDate(context.date(day), equalTo: context.date(other), toGranularity: .weekOfYear)
    }

    private nonisolated static func monthGroups(_ context: InsightsContext) -> [[DiaryDay]] {
        Dictionary(grouping: context.days, by: \.month).sorted { $0.key < $1.key }.map(\.value)
    }

    nonisolated static func clock(_ minute: Int, _ style: Date.FormatStyle, _ context: InsightsContext) -> String {
        let date = context.calendar.date(
            bySettingHour: minute / 60 % 24, minute: minute % 60, second: 0, of: context.interval.start
        )
        return context.format(date ?? context.interval.start, style)
    }

    private nonisolated static func loggedDayCount(_ count: Int) -> String {
        count == 1 ? String(localized: "insights.loggedDays.one", bundle: .module)
            : String(localized: "insights.loggedDays \(count)", bundle: .module)
    }

    private nonisolated static func breakdownTitle(_ context: InsightsContext) -> String {
        let count = context.days.count
        guard context.source.offset == 0 else { return String(localized: "insights.breakdown \(count)", bundle: .module) }
        return switch context.source.period {
        case .week: String(localized: "insights.breakdown.week \(count)", bundle: .module)
        case .month: String(localized: "insights.breakdown.month \(count)", bundle: .module)
        case .year: String(localized: "insights.breakdown.year \(count)", bundle: .module)
        }
    }

    private nonisolated static func breakdown(_ context: InsightsContext) -> [InsightsBreakdownViewData] {
        let marks = context.days.map(context.marks.mark)
        let logged = marks.count {
            if case .logs = $0 {
                true
            } else {
                false
            }
        }
        return [
            row("logged", .logs(1), "insights.breakdown.logged", logged),
            row("noPoop", .noPoop, "insights.breakdown.noPoop", marks.count { $0 == .noPoop }),
            row("noneSoFar", .noneSoFar, "insights.breakdown.noneSoFar", marks.count { $0 == .noneSoFar }),
            row("unrecorded", .unrecorded, "insights.breakdown.unrecorded", marks.count { $0 == .unrecorded }),
            row("future", nil, "insights.breakdown.future", marks.count { $0 == .future || $0 == .open }),
        ] + untracked(marks)
    }

    private nonisolated static func untracked(_ marks: [DayMarkViewData]) -> [InsightsBreakdownViewData] {
        let count = marks.count { $0 == .untracked }
        return count == 0 ? [] : [row("untracked", nil, "insights.breakdown.untracked", count)]
    }

    private nonisolated static func row(
        _ id: String, _ mark: DayMarkViewData?, _ key: String.LocalizationValue, _ count: Int
    ) -> InsightsBreakdownViewData {
        InsightsBreakdownViewData(
            id: id, mark: mark, title: String(localized: key, bundle: .module), count: count.formatted()
        )
    }
}
