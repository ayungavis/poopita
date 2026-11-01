import Foundation

extension TodayViewModel {
    static func dayState(
        hasLogs: Bool,
        latestEntry: DiaryEntry?,
        checkIn: NoPoopCheckIn?,
        pastWeekday: String?,
        now: Date
    ) throws -> TodayDayStateViewData {
        if hasLogs {
            return .logged
        }
        guard let weekday = pastWeekday else {
            let partialNote = try checkIn.map {
                try String(localized: "today.notYetNote \(timeLabel($0.reportedAt))", bundle: .module)
            }
            guard let latestEntry else {
                return .waiting(
                    headline: String(localized: "today.hero.empty", bundle: .module), detail: nil, partialNote: partialNote
                )
            }
            let seconds = max(0, now.timeIntervalSince(latestEntry.occurrence.instant))
            let headline = Duration.seconds(seconds).formatted(
                .units(allowed: [.days, .hours], width: .wide, fractionalPart: .hide(rounded: .down))
            )
            let lastDay = try dayLabel(latestEntry.occurrence, now: now)
            let lastTime = try timeLabel(latestEntry.occurrence)
            return .waiting(
                headline: headline,
                detail: String(localized: "today.sinceLastLog \(lastDay) \(lastTime)", bundle: .module),
                partialNote: partialNote
            )
        }
        let logLabel = String(localized: "today.logFor \(weekday)", bundle: .module)
        switch checkIn?.coverage {
        case .completed:
            return .pastDay(
                status: String(localized: "checkIn.completed", bundle: .module),
                detail: String(localized: "checkIn.completedDetail", bundle: .module),
                logLabel: logLabel, canConfirm: false
            )
        case .partial:
            let reported = try checkIn.map { try timeLabel($0.reportedAt) } ?? ""
            return .pastDay(
                status: String(localized: "checkIn.partial", bundle: .module),
                detail: String(localized: "checkIn.partialDetail \(reported)", bundle: .module),
                logLabel: logLabel, canConfirm: true
            )
        case nil:
            return .pastDay(
                status: String(localized: "checkIn.unknown", bundle: .module),
                detail: String(localized: "checkIn.unknownDetail", bundle: .module),
                logLabel: logLabel, canConfirm: true
            )
        }
    }

    static func timeline(
        dayEntries: [DiaryEntry], isToday: Bool, now: Date, activeDate: Date, calendar: Calendar
    ) throws -> TodayTimelineViewData {
        let nowParts = calendar.dateComponents([.hour, .minute], from: now)
        let nowHour = nowParts.hour ?? 0
        let firstHour = dayEntries.first?.occurrence.hour ?? 6
        let lastHour = dayEntries.last?.occurrence.hour ?? 0
        let startHour = min(6, firstHour, isToday ? max(0, nowHour - 3) : 6)
        let endHour = min(23, max(isToday ? nowHour + 4 : 21, lastHour + 1))
        var hourStyle = Date.FormatStyle.dateTime.hour().minute()
        hourStyle.timeZone = calendar.timeZone

        let hours = (startHour ... endHour).map { hour in
            let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: activeDate) ?? activeDate
            return TodayTimelineHourViewData(minute: (hour - startHour) * 60, label: date.formatted(hourStyle))
        }
        let blocks = try dayEntries.map { entry in
            try TodayTimelineBlockViewData(
                minute: entry.occurrence.hour * 60 + entry.occurrence.minute - startHour * 60, entry: row(entry)
            )
        }
        let nowMark = isToday
            ? TodayTimelineMarkViewData(
                minute: nowHour * 60 + (nowParts.minute ?? 0) - startHour * 60, label: now.formatted(hourStyle)
            )
            : nil
        let sinceLast: TodayTimelineMarkViewData? = if isToday, let entry = dayEntries.last, let block = blocks.last {
            sinceLastMark(entry: entry, block: block, now: now)
        } else {
            nil
        }
        return TodayTimelineViewData(
            hours: hours, blocks: blocks, now: nowMark, sinceLast: sinceLast,
            endMinute: (endHour - startHour + 1) * 60
        )
    }

    private static func sinceLastMark(
        entry: DiaryEntry, block: TodayTimelineBlockViewData, now: Date
    ) -> TodayTimelineMarkViewData {
        let seconds = max(0, now.timeIntervalSince(entry.occurrence.instant))
        let elapsed = Duration.seconds(seconds).formatted(.units(
            allowed: [.hours, .minutes],
            width: .abbreviated,
            fractionalPart: .hide(rounded: .down)
        ))
        return TodayTimelineMarkViewData(
            minute: block.minute,
            label: String(localized: "today.since \(block.entry.timeLabel) \(elapsed)", bundle: .module)
        )
    }

    private static func timeLabel(_ occurrence: OccurrenceTime) throws -> String {
        try occurrence.instant.formatted(style(.dateTime.hour().minute(), occurrence))
    }

    private static func dayLabel(_ occurrence: OccurrenceTime, now: Date) throws -> String {
        let isThisWeek = now.timeIntervalSince(occurrence.instant) < 6 * 86400
        let base: Date.FormatStyle = isThisWeek ? .dateTime.weekday(.wide) : .dateTime.month(.abbreviated).day()
        return try occurrence.instant.formatted(style(base, occurrence))
    }

    private static func style(_ base: Date.FormatStyle, _ occurrence: OccurrenceTime) throws -> Date.FormatStyle {
        guard let zone = TimeZone(secondsFromGMT: occurrence.utcOffsetSeconds) else { throw AppError.invalidStoredData }
        var style = base
        style.timeZone = zone
        return style
    }

    static func row(_ entry: DiaryEntry) throws -> TodayEntryViewData {
        guard let zone = TimeZone(secondsFromGMT: entry.occurrence.utcOffsetSeconds) else {
            throw AppError.invalidStoredData
        }
        var dateStyle = Date.FormatStyle.dateTime.year().month(.abbreviated).day()
        var timeStyle = Date.FormatStyle.dateTime.hour().minute()
        dateStyle.timeZone = zone
        timeStyle.timeZone = zone
        let title: String
        var illustration: EntryIllustrationKind?
        if let type = entry.stoolType {
            guard let choice = EntryChoiceViewData.types.first(where: { $0.id == String(type) }) else {
                throw AppError.invalidStoredData
            }
            title = choice.title + " · " + choice.detail
            illustration = choice.illustration
        } else {
            title = String(localized: "entry.typeSkipped", bundle: .module)
        }
        var observations = [title]
        if let amount = entry.amount {
            let choice = EntryChoiceViewData.amounts.first { $0.id == amount.rawValue }
            guard let choice else { throw AppError.invalidStoredData }
            observations.append(String(localized: "entry.amountLabel", bundle: .module) + ": " + choice.title)
        }
        if let effort = entry.effort {
            let choice = EntryChoiceViewData.efforts.first { $0.id == effort.rawValue }
            guard let choice else { throw AppError.invalidStoredData }
            observations.append(String(localized: "entry.effortLabel", bundle: .module) + ": " + choice.title)
        }
        return TodayEntryViewData(
            id: entry.id, dateLabel: entry.occurrence.instant.formatted(dateStyle),
            timeLabel: entry.occurrence.instant.formatted(timeStyle), title: title, illustration: illustration,
            observations: observations.joined(separator: " · "), note: entry.note
        )
    }
}
