import Foundation

extension PatternsViewModel {
    struct ActivityContext {
        let maxCount: Int
        let range: PatternsRange
        let calendar: Calendar
    }

    static func dailyActivity(
        for day: DiaryDay, count: Int, coverage: NoPoopCheckIn.Coverage?, context: ActivityContext
    ) -> PatternsDailyActivityViewData {
        let status: PatternsDayStatus
        let mark: String
        if count > 0 {
            status = .logged
            mark = "\(count)"
        } else if coverage == .completed {
            status = .confirmedNoPoop
            mark = "0"
        } else if coverage == .partial {
            status = .partialCheckIn
            mark = "…"
        } else {
            status = .unrecorded
            mark = "—"
        }
        let date = date(for: day, calendar: context.calendar)
        let label = context.range == .sevenDays
            ? formatted(date, style: .dateTime.weekday(.narrow), calendar: context.calendar) : "\(day.day)"
        let description = switch status {
        case .logged: String(localized: "patterns.status.logged \(count)", bundle: .module)
        case .confirmedNoPoop: String(localized: "checkIn.completed", bundle: .module)
        case .partialCheckIn: String(localized: "checkIn.noneSoFar", bundle: .module)
        case .unrecorded: String(localized: "checkIn.unknown", bundle: .module)
        }
        let dateLabel = formatted(
            date,
            style: .dateTime.weekday(.wide).month(.abbreviated).day().year(),
            calendar: context.calendar
        )
        return PatternsDailyActivityViewData(
            dayID: day.id, label: label, count: count, ratio: Double(count) / Double(context.maxCount),
            status: status, statusMark: mark, accessibilityLabel: "\(dateLabel): \(description)"
        )
    }

    static func activityBuckets(
        for activity: [PatternsDailyActivityViewData], days: [DiaryDay], range: PatternsRange, calendar: Calendar
    ) -> [PatternsActivityBucketViewData] {
        guard range == .oneYear else {
            return zip(days, activity).map { day, item in
                PatternsActivityBucketViewData(
                    id: item.dayID, label: item.label,
                    detailLabel: formatted(
                        date(for: day, calendar: calendar),
                        style: .dateTime.weekday(.wide).month(.wide).day().year(), calendar: calendar
                    ),
                    count: item.count, dayIDs: [item.dayID], coverage: coverageSummary([item]), isPartial: false
                )
            }
        }
        let byMonth = Dictionary(grouping: zip(days, activity)) { pair in
            "\(pair.0.year)-\(pair.0.month)"
        }
        return byMonth.values.sorted { $0[0].0 < $1[0].0 }.map { pairs in
            let first = pairs[0].0
            let last = pairs[pairs.count - 1].0
            let date = date(for: first, calendar: calendar)
            let items = pairs.map(\.1)
            return PatternsActivityBucketViewData(
                id: "\(first.year)-\(first.month)",
                label: formatted(date, style: .dateTime.month(.abbreviated), calendar: calendar),
                detailLabel: formatted(date, style: .dateTime.month(.wide).year(), calendar: calendar),
                count: items.map(\.count).reduce(0, +), dayIDs: items.map(\.dayID), coverage: coverageSummary(items),
                isPartial: first.day != 1 || last.day != calendar.range(of: .day, in: .month, for: date)?.count
            )
        }
    }
}
