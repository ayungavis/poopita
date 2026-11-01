import Foundation

extension InsightsViewModel {
    nonisolated static func usual(_ context: InsightsContext, baseline: InsightsBaseline?) -> InsightsUsualViewData {
        guard let baseline else {
            let key: String.LocalizationValue = context.source.period == .year
                ? "insights.usual.basis.year" : "insights.usual.notEnough"
            return InsightsUsualViewData(rows: [], note: String(localized: key, bundle: .module))
        }
        let note = String(
            localized: context.source.period == .week ? "insights.usual.basis.week" : "insights.usual.basis.month",
            bundle: .module
        )
        let rows = [
            oftenRow(context, baseline: baseline),
            typeRow(context, baseline: baseline),
            timeRow(context, baseline: baseline),
        ]
        return InsightsUsualViewData(rows: rows.compactMap(\.self), note: note)
    }

    private nonisolated static func oftenRow(
        _ context: InsightsContext, baseline: InsightsBaseline
    ) -> InsightsUsualRowViewData? {
        let recorded = context.recordedDays.count
        guard recorded > 0, let usual = InsightsStats.range(baseline.counts) else { return nil }
        let current = Double(context.pastLogs.count) / Double(recorded)
        let scale = Double(max(3, usual.upperBound + 1, Int(current.rounded(.up))))
        return InsightsUsualRowViewData(
            id: "often", label: String(localized: "insights.usual.often", bundle: .module),
            value: String(localized: "insights.usual.oftenValue \(perDayLabel(current)) \(rangeLabel(usual))", bundle: .module),
            lower: Double(usual.lowerBound) / scale, upper: Double(usual.upperBound) / scale, current: current / scale
        )
    }

    private nonisolated static func typeRow(_ context: InsightsContext, baseline: InsightsBaseline) -> InsightsUsualRowViewData? {
        guard let usual = InsightsStats.range(baseline.logs.compactMap(\.stoolType)),
              let mostly = InsightsStats.mode(context.pastLogs.compactMap(\.stoolType))
        else { return nil }
        return InsightsUsualRowViewData(
            id: "type", label: String(localized: "insights.usual.type", bundle: .module),
            value: String(localized: "insights.usual.typeValue \(mostly) \(rangeLabel(usual))", bundle: .module),
            lower: Double(usual.lowerBound - 1) / 6, upper: Double(usual.upperBound - 1) / 6, current: Double(mostly - 1) / 6
        )
    }

    private nonisolated static func timeRow(_ context: InsightsContext, baseline: InsightsBaseline) -> InsightsUsualRowViewData? {
        guard let window = usualWindow(baseline),
              let median = InsightsStats.median(context.pastLogs.map(minute)) else { return nil }
        let style = Date.FormatStyle.dateTime.hour().minute()
        let usual = clock(window.lowerBound, style, context) + "–" + clock(window.upperBound, style, context)
        return InsightsUsualRowViewData(
            id: "time", label: String(localized: "insights.usual.time", bundle: .module),
            value: String(localized: "insights.usual.timeValue \(clock(median, style, context)) \(usual)", bundle: .module),
            lower: Double(window.lowerBound) / 1440, upper: Double(window.upperBound) / 1440, current: Double(median) / 1440
        )
    }

    nonisolated static func consistency(_ context: InsightsContext) -> InsightsConsistencyViewData {
        let rows = shareGroups(context).map { group in
            shareRow(group.days, label: group.label, isCurrent: group.days.contains(context.today), context: context)
        }
        let typed = context.pastLogs.compactMap(\.stoolType)
        guard !typed.isEmpty else { return InsightsConsistencyViewData(lead: nil, rows: rows) }
        let hard = typed.count { $0 <= 2 }
        let loose = typed.count { $0 >= 6 }
        let lead = if loose * 4 > typed.count {
            String(localized: "insights.consistency.loose \(loose) \(typed.count) \(loose * 100 / typed.count)", bundle: .module)
        } else if hard * 4 > typed.count {
            String(localized: "insights.consistency.hard \(hard) \(typed.count) \(hard * 100 / typed.count)", bundle: .module)
        } else {
            String(localized: "insights.consistency.under \(hard) \(loose) \(typed.count)", bundle: .module)
        }
        return InsightsConsistencyViewData(lead: lead, rows: rows)
    }

    private nonisolated static func shareGroups(_ context: InsightsContext) -> [(label: String, days: [DiaryDay])] {
        switch context.source.period {
        case .week:
            return (-3 ... 0).compactMap { weeks in
                guard let start = context.calendar.date(byAdding: .day, value: weeks * 7, to: context.interval.start)
                else { return nil }
                let days = (0 ..< 7).compactMap { offset in
                    context.calendar.date(byAdding: .day, value: offset, to: start)
                        .flatMap { try? DiaryDay(date: $0, timeZone: context.calendar.timeZone) }
                }
                let isThisWeek = weeks == 0 && context.source.offset == 0
                let label = isThisWeek ? String(localized: "insights.thisWeek", bundle: .module)
                    : context.span(days)
                return (label, days)
            }
        case .month:
            return weekGroups(context).map { (context.span($0), $0) }
        case .year:
            let first = context.marks.firstDay
            return monthGroups(context)
                .filter { group in
                    guard let start = group.first, let end = group.last, let first else { return false }
                    return end >= first && start <= context.today
                }
                .map { group in
                    let name = context.format(context.date(group.first ?? context.today), .dateTime.month(.abbreviated))
                    let label = group
                        .contains(context.today) ? String(localized: "insights.soFar \(name)", bundle: .module) : name
                    return (label, group)
                }
        }
    }

    private nonisolated static func shareRow(
        _ days: [DiaryDay], label: String, isCurrent: Bool, context: InsightsContext
    ) -> InsightsShareRowViewData {
        let typed = days.flatMap { context.marks.logs[$0] ?? [] }.compactMap(\.stoolType)
        let hard = typed.count { $0 <= 2 }
        let loose = typed.count { $0 >= 6 }
        let total = Double(max(typed.count, 1))
        return InsightsShareRowViewData(
            id: days.first?.id ?? label, label: label,
            hard: Double(hard) / total, usual: Double(typed.count - hard - loose) / total, loose: Double(loose) / total,
            isCurrent: isCurrent && context.source.period != .year, isDimmed: isCurrent && context.source.period == .year,
            accessibilityLabel: String(
                localized: "insights.consistency.row \(label) \(hard) \(typed.count - hard - loose) \(loose)", bundle: .module
            )
        )
    }

    nonisolated static func comfort(_ context: InsightsContext, baseline: InsightsBaseline?) -> [InsightsComfortRowViewData] {
        let logs = context.pastLogs
        var rows: [InsightsComfortRowViewData] = []
        let rated = logs.filter { $0.effort != nil }
        if !rated.isEmpty {
            let difficult = rated.count { $0.effort == .difficult }
            let share = Double(difficult) / Double(rated.count)
            let usualRated = baseline?.logs.filter { $0.effort != nil } ?? []
            let usual = usualRated.isEmpty ? nil : Double(usualRated.count { $0.effort == .difficult }) / Double(usualRated.count)
            rows.append(comfortRow(
                "straining", label: "insights.comfort.straining",
                value: String(localized: "insights.comfort.strainingValue \(difficult) \(rated.count)", bundle: .module),
                versus: baseline == nil ? nil : versus(share, usual ?? 0, tolerance: 0.15)
            ))
        }
        let duration = choiceRow("duration", label: "insights.comfort.duration", logs: logs, baseline: baseline,
                                 field: \.duration?.rawValue)
        let amount = choiceRow("amount", label: "insights.comfort.amount", logs: logs, baseline: baseline,
                               field: \.amount?.rawValue)
        rows += [duration, amount].compactMap(\.self)
        return rows
    }

    private nonisolated static func choiceRow(
        _ id: String, label: String.LocalizationValue, logs: [DiaryEntry], baseline: InsightsBaseline?,
        field value: KeyPath<DiaryEntry, String?>
    ) -> InsightsComfortRowViewData? {
        let choices = id == "duration" ? EntryChoiceViewData.durations : EntryChoiceViewData.amounts
        let ids = choices.map(\.id)
        guard let mostly = InsightsStats.mode(logs.compactMap { $0[keyPath: value] }.compactMap { ids.firstIndex(of: $0) })
        else { return nil }
        let usual = baseline
            .flatMap { InsightsStats.mode($0.logs.compactMap { $0[keyPath: value] }.compactMap { ids.firstIndex(of: $0) }) }
        let title = choices[mostly].title.localizedLowercase
        return comfortRow(
            id, label: label, value: String(localized: "insights.comfort.mostly \(title)", bundle: .module),
            versus: baseline == nil ? nil : versus(Double(mostly), Double(usual ?? mostly), tolerance: 0)
        )
    }

    private nonisolated static func comfortRow(
        _ id: String, label: String.LocalizationValue, value: String, versus: String?
    ) -> InsightsComfortRowViewData {
        InsightsComfortRowViewData(
            id: id, label: String(localized: label, bundle: .module),
            value: [value, versus].compactMap(\.self).joined(separator: " · ")
        )
    }

    private nonisolated static func versus(_ value: Double, _ usual: Double, tolerance: Double) -> String {
        if value > usual + tolerance {
            return String(localized: "insights.vs.more", bundle: .module)
        }
        if value < usual - tolerance {
            return String(localized: "insights.vs.less", bundle: .module)
        }
        return String(localized: "insights.vs.asUsual", bundle: .module)
    }
}
