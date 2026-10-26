import Foundation

extension PatternsViewModel {
    static func dayDetail(
        for day: DiaryDay, entries: [DiaryEntry], coverage: NoPoopCheckIn.Coverage?, calendar: Calendar
    ) -> PatternsDayDetailViewData {
        let date = date(for: day, calendar: calendar)
        let dayEntries = entries.sorted { $0.occurrence.instant < $1.occurrence.instant }
        let status = if !dayEntries.isEmpty {
            String(localized: "patterns.day.status.logged", bundle: .module)
        } else if coverage == .completed {
            String(localized: "checkIn.completed", bundle: .module)
        } else if coverage == .partial {
            String(localized: "checkIn.noneSoFar", bundle: .module)
        } else {
            String(localized: "checkIn.unknown", bundle: .module)
        }

        let items = dayEntries.map { entry in
            PatternsEntryViewData(
                id: entry.id,
                timeLabel: timeLabel(for: entry.occurrence),
                stoolType: entry.stoolType.flatMap { type in
                    EntryChoiceViewData.types.first { $0.id == String(type) }?.title
                } ?? String(localized: "entry.typeSkipped", bundle: .module),
                amount: entry.amount.flatMap { amount in
                    EntryChoiceViewData.amounts.first { $0.id == amount.rawValue }?.title
                },
                effort: entry.effort.flatMap { effort in
                    EntryChoiceViewData.efforts.first { $0.id == effort.rawValue }?.title
                },
                note: entry.note.isEmpty ? nil : entry.note
            )
        }
        return PatternsDayDetailViewData(
            dayID: day.id,
            weekdaySymbol: formatted(date, style: .dateTime.weekday(.narrow), calendar: calendar),
            dayNumber: formatted(date, style: .dateTime.day(), calendar: calendar),
            dateLabel: formatted(date, style: .dateTime.weekday(.wide).month(.wide).day().year(), calendar: calendar),
            statusLabel: status,
            statusMark: statusMark(entryCount: dayEntries.count, coverage: coverage),
            entryCount: dayEntries.count,
            entries: items
        )
    }

    static func timeLabel(for occurrence: OccurrenceTime) -> String {
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.timeZone = TimeZone(secondsFromGMT: occurrence.utcOffsetSeconds) ?? .gmt
        return occurrence.instant.formatted(style)
    }

    private static func statusMark(entryCount: Int, coverage: NoPoopCheckIn.Coverage?) -> String {
        guard entryCount == 0 else { return "●" }
        switch coverage {
        case .completed: return "0"
        case .partial: return "…"
        case nil: return "—"
        }
    }
}
