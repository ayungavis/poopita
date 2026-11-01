import Foundation

extension InsightsViewModel {
    nonisolated static func doctorFlags(_ context: InsightsContext) -> [InsightsFlagViewData] {
        let logs = context.pastLogs.sorted { $0.occurrence.instant < $1.occurrence.instant }
        var flags: [InsightsFlagViewData] = []
        let bloody = logs.filter { $0.blood == .seen }
        if let first = bloody.first {
            flags.append(InsightsFlagViewData(
                id: "blood",
                title: dayCount(bloody) == 1
                    ? String(localized: "insights.doctor.bloodOn \(dayName(first, context))", bundle: .module)
                    : String(localized: "insights.doctor.bloodDays \(dayCount(bloody))", bundle: .module),
                detail: dayCount(bloody) == 1
                    ? String(localized: "insights.doctor.bloodOnce \(clock(first, context))", bundle: .module)
                    : String(localized: "insights.doctor.continues", bundle: .module),
                dayID: DiaryDay(occurrence: first.occurrence).id
            ))
        }
        if let first = logs.first(where: { $0.color == .black }) {
            flags.append(colorFlag("black", first, context, detail: "insights.doctor.blackDetail"))
        }
        if let first = logs.first(where: { $0.color == .red && $0.blood != .seen }) {
            flags.append(colorFlag("red", first, context, detail: "insights.doctor.again"))
        }
        let pale = logs.filter { $0.color == .pale }
        if let first = pale.first, dayCount(pale) >= 2 {
            flags.append(InsightsFlagViewData(
                id: "pale", title: String(localized: "insights.doctor.paleDays \(dayCount(pale))", bundle: .module),
                detail: String(localized: "insights.doctor.continues", bundle: .module),
                dayID: DiaryDay(occurrence: first.occurrence).id
            ))
        }
        return flags
    }

    nonisolated static func doctorSummary(_ flags: [InsightsFlagViewData]) -> String? {
        guard let first = flags.first else { return nil }
        guard flags.count == 1 else { return String(localized: "insights.doctor.summary \(flags.count)", bundle: .module) }
        let short = switch first.id {
        case "blood": String(localized: "insights.doctor.short.blood", bundle: .module)
        case "black": String(localized: "insights.doctor.short.black", bundle: .module)
        case "red": String(localized: "insights.doctor.short.red", bundle: .module)
        default: String(localized: "insights.doctor.short.pale", bundle: .module)
        }
        return String(localized: "insights.doctor.summaryOne \(short)", bundle: .module)
    }

    nonisolated static func changes(_ context: InsightsContext, baseline: InsightsBaseline?) -> [InsightsFlagViewData] {
        guard context.isSettled else { return [] }
        let logs = context.pastLogs.sorted { $0.occurrence.instant < $1.occurrence.instant }
        var flags = formChanges(logs, context: context, baseline: baseline)
        guard let baseline else { return flags }
        if let fewer = fewer(context, baseline: baseline) {
            flags.append(fewer)
        }
        if let timing = timing(logs, context: context, baseline: baseline) {
            flags.append(timing)
        }
        if let straining = straining(logs, baseline: baseline) {
            flags.append(straining)
        }
        return flags
    }

    private nonisolated static func formChanges(
        _ logs: [DiaryEntry], context: InsightsContext, baseline: InsightsBaseline?
    ) -> [InsightsFlagViewData] {
        guard logs.count(where: { $0.stoolType != nil }) >= 4 else { return [] }
        var flags: [InsightsFlagViewData] = []
        let loose = InsightsStats.share(logs) { $0 >= 6 }
        if loose > 0.25, loose > InsightsStats.share(baseline?.logs ?? []) { $0 >= 6 } {
            let matching = logs.filter { ($0.stoolType ?? 0) >= 6 }
            flags.append(InsightsFlagViewData(
                id: "looser", title: String(localized: "insights.change.looser", bundle: .module),
                detail: String(localized: "insights.change.looserDetail \(days(matching, context))", bundle: .module),
                dayID: matching.first.map { DiaryDay(occurrence: $0.occurrence).id }
            ))
        }
        let hard = InsightsStats.share(logs) { $0 <= 2 }
        if hard > 0.25, hard > InsightsStats.share(baseline?.logs ?? []) { $0 <= 2 } {
            let matching = logs.filter { ($0.stoolType ?? 9) <= 2 }
            flags.append(InsightsFlagViewData(
                id: "harder", title: String(localized: "insights.change.harder", bundle: .module),
                detail: String(localized: "insights.change.harderDetail \(days(matching, context))", bundle: .module),
                dayID: matching.first.map { DiaryDay(occurrence: $0.occurrence).id }
            ))
        }
        return flags
    }

    private nonisolated static func fewer(_ context: InsightsContext, baseline: InsightsBaseline) -> InsightsFlagViewData? {
        let recorded = context.recordedDays
        guard let usual = InsightsStats.range(baseline.counts) else { return nil }
        let perDay = Double(context.pastLogs.count) / Double(recorded.count)
        guard perDay < Double(usual.lowerBound) else { return nil }
        return InsightsFlagViewData(
            id: "fewer", title: String(localized: "insights.change.fewer", bundle: .module),
            detail: String(localized: "insights.change.fewerDetail \(perDayLabel(perDay)) \(rangeLabel(usual))", bundle: .module),
            dayID: recorded.first?.id
        )
    }

    private nonisolated static func timing(
        _ logs: [DiaryEntry], context: InsightsContext, baseline: InsightsBaseline
    ) -> InsightsFlagViewData? {
        guard logs.count >= 5, let window = usualWindow(baseline) else { return nil }
        let outside = logs.filter { !window.contains(minute($0)) }
        guard outside.count * 2 > logs.count, let median = InsightsStats.median(logs.map(minute)) else { return nil }
        let isLater = median > window.upperBound
        let from = clock(window.lowerBound, context)
        let until = clock(window.upperBound, context)
        return InsightsFlagViewData(
            id: "timing",
            title: String(localized: isLater ? "insights.change.later" : "insights.change.earlier", bundle: .module),
            detail: String(localized: "insights.change.timingDetail \(from) \(until)", bundle: .module),
            dayID: outside.first.map { DiaryDay(occurrence: $0.occurrence).id }
        )
    }

    private nonisolated static func straining(_ logs: [DiaryEntry], baseline: InsightsBaseline) -> InsightsFlagViewData? {
        let rated = logs.filter { $0.effort != nil }
        guard rated.count >= 4 else { return nil }
        let difficult = rated.filter { $0.effort == .difficult }
        let share = Double(difficult.count) / Double(rated.count)
        let usualRated = baseline.logs.filter { $0.effort != nil }
        let usualShare = usualRated.isEmpty ? 0 : Double(usualRated.count { $0.effort == .difficult }) / Double(usualRated.count)
        guard share > 0.25, share > usualShare else { return nil }
        return InsightsFlagViewData(
            id: "straining", title: String(localized: "insights.change.straining", bundle: .module),
            detail: String(localized: "insights.change.strainingDetail \(difficult.count) \(rated.count)", bundle: .module),
            dayID: difficult.first.map { DiaryDay(occurrence: $0.occurrence).id }
        )
    }

    nonisolated static func usualWindow(_ baseline: InsightsBaseline) -> ClosedRange<Int>? {
        guard let range = InsightsStats.range(baseline.logs.map(minute)) else { return nil }
        return range.lowerBound / 60 * 60 ... min(24 * 60, (range.upperBound / 60 + 1) * 60)
    }

    nonisolated static func minute(_ entry: DiaryEntry) -> Int {
        entry.occurrence.hour * 60 + entry.occurrence.minute
    }

    nonisolated static func perDayLabel(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... 1)))
    }

    nonisolated static func rangeLabel(_ range: ClosedRange<Int>) -> String {
        range.lowerBound == range.upperBound ? String(range.lowerBound) : "\(range.lowerBound)–\(range.upperBound)"
    }

    private nonisolated static func colorFlag(
        _ id: String, _ entry: DiaryEntry, _ context: InsightsContext, detail: String.LocalizationValue
    ) -> InsightsFlagViewData {
        let day = dayName(entry, context)
        let title = id == "black" ? String(localized: "insights.doctor.blackOn \(day)", bundle: .module)
            : String(localized: "insights.doctor.redOn \(day)", bundle: .module)
        return InsightsFlagViewData(
            id: id, title: title, detail: String(localized: detail, bundle: .module),
            dayID: DiaryDay(occurrence: entry.occurrence).id
        )
    }

    private nonisolated static func dayName(_ entry: DiaryEntry, _ context: InsightsContext) -> String {
        context.format(
            context.date(DiaryDay(occurrence: entry.occurrence)),
            .dateTime.weekday(.abbreviated).day().month(.abbreviated)
        )
    }

    private nonisolated static func clock(_ entry: DiaryEntry, _ context: InsightsContext) -> String {
        clock(minute(entry), context)
    }

    private nonisolated static func clock(_ minute: Int, _ context: InsightsContext) -> String {
        clock(minute, .dateTime.hour().minute(), context)
    }

    private nonisolated static func dayCount(_ logs: [DiaryEntry]) -> Int {
        Set(logs.map { DiaryDay(occurrence: $0.occurrence) }).count
    }

    private nonisolated static func days(_ logs: [DiaryEntry], _ context: InsightsContext) -> String {
        let days = Set(logs.map { DiaryDay(occurrence: $0.occurrence) }).sorted()
        guard context.source.period == .week else { return dayCount(days.count) }
        return days.map { context.format(context.date($0), .dateTime.weekday(.abbreviated)) }
            .formatted(.list(type: .and))
    }
}
