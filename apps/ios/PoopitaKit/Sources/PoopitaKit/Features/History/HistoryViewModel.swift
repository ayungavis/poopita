import Foundation
import Observation

@MainActor
@Observable
final class HistoryViewModel {
    private(set) var state: Loadable<HistoryViewData> = .idle
    private var selectedDay: DiaryDay
    private(set) var editor: EntryEditorViewModel?
    private(set) var errorMessage: String?
    private(set) var feedback: String?
    private let repository: any DiaryRepository
    private let now: () -> Date
    private let timeZone: () -> TimeZone
    private var month: Date

    init(repository: any DiaryRepository, now: @escaping () -> Date, timeZone: @escaping () -> TimeZone) throws {
        self.repository = repository
        self.now = now
        self.timeZone = timeZone
        let current = now()
        selectedDay = try DiaryDay(date: current, timeZone: timeZone())
        month = Self.monthStart(current, timeZone: timeZone())
    }

    func load() {
        month = Self.monthStart(month, timeZone: timeZone())
        state = .loading
        do {
            state = try .loaded(Self.viewData(HistorySourceData(
                entries: repository.entries(), checkIns: repository.checkIns(), month: month,
                selectedDay: selectedDay, today: now(), timeZone: timeZone(), canUndo: repository.canUndo
            )))
            errorMessage = nil
        } catch {
            let failure = AppError(wrapping: error)
            state = .failed(failure)
            errorMessage = failure.userMessage
            Log.report(error, context: Log.Context(operation: "diary.history"))
        }
    }

    func select(id: String) {
        let parts = id.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return }
        let day = try? DiaryDay(
            date: calendar().date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) ?? .now,
            timeZone: timeZone()
        )
        guard let day, (try? day.validate()) != nil, day <= todayDay(), visibleMonthContains(day) else { return }
        selectedDay = day
        month = Self.monthStart(Self.date(for: day, calendar: calendar()), timeZone: timeZone())
        load()
    }

    func moveMonth(_ amount: Int) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone()
        guard let next = calendar.date(byAdding: .month, value: amount, to: month),
              amount < 0 || next <= now(),
              let interval = calendar.dateInterval(of: .month, for: next),
              let days = calendar.range(of: .day, in: .month, for: interval.start),
              let selectedDate = calendar.date(byAdding: .day, value: min(selectedDay.day, days.count) - 1,
                                               to: interval.start),
              let newSelection = try? DiaryDay(date: selectedDate, timeZone: timeZone())
        else { return }
        month = interval.start
        selectedDay = newSelection
        load()
    }

    func showToday() {
        month = Self.monthStart(now(), timeZone: timeZone())
        selectedDay = todayDay()
        load()
    }

    func edit(id: UUID) {
        do {
            guard let entry = try repository.entries().first(where: { $0.id == id }) else { throw AppError.notFound }
            editor = try EntryEditorViewModel(
                repository: repository, entryID: id, draft: EntryEditorViewModel.viewData(for: entry), now: now
            )
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }

    func addEntry() {
        do {
            let zone = timeZone()
            var components = DateComponents(year: selectedDay.year, month: selectedDay.month, day: selectedDay.day,
                                            hour: 12)
            components.timeZone = zone
            guard let occurrenceDate = Calendar(identifier: .gregorian).date(from: components) else {
                throw AppError.invalidOccurrence
            }
            editor = try EntryEditorViewModel(
                repository: repository, entryID: UUID(),
                draft: EntryEditorViewData(
                    occurrenceDate: occurrenceDate, timeZoneIdentifier: zone.identifier,
                    stoolType: nil, amount: nil, effort: nil, note: ""
                ), now: now
            )
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }

    func dismissEditor() {
        editor = nil
    }

    func savedEditor() {
        feedback = editor?.saveMessage ?? String(localized: "diary.saved", bundle: .module)
        editor = nil
        load()
    }

    func delete(id: UUID) -> Bool {
        do {
            try repository.delete(id: id)
            feedback = String(localized: "diary.deleted", bundle: .module)
            load()
            return true
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
            return false
        }
    }

    func confirmNoPoop() -> Bool {
        do {
            let report = try OccurrenceTime(instant: now(), timeZone: timeZone())
            guard DiaryDay(occurrence: report) > selectedDay else { throw AppError.invalidCheckIn }
            let checkIn = NoPoopCheckIn(day: selectedDay, reportedAt: report, coverage: .completed)
            try repository.saveCheckIn(checkIn)
            feedback = String(localized: "checkIn.saved", bundle: .module)
            load()
            return true
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
            return false
        }
    }

    func undo() {
        do {
            try repository.undo()
            feedback = String(localized: "diary.undone", bundle: .module)
            errorMessage = nil
            load()
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }

    var calendarState: HistoryCalendarViewData? {
        guard case let .loaded(data) = state else { return nil }
        return data.calendar
    }

    private func todayDay() -> DiaryDay {
        (try? DiaryDay(date: now(), timeZone: timeZone())) ?? selectedDay
    }

    static func viewData(_ source: HistorySourceData) throws -> HistoryViewData {
        let calendar = gregorianCalendar(source.timeZone)
        guard let monthStart = calendar.dateInterval(of: .month, for: source.month)?.start,
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart)
        else { throw AppError.invalidOccurrence }
        let today = try DiaryDay(date: source.today, timeZone: source.timeZone)
        let days = try calendarDays(source, calendar: calendar, monthStart: monthStart, count: monthRange.count)
        let selectedEntries = source.entries.filter { DiaryDay(occurrence: $0.occurrence) == source.selectedDay }
        return try HistoryViewData(
            monthLabel: monthStart.formatted(.dateTime.month(.wide).year()),
            canMoveNext: monthStart < (calendar.dateInterval(of: .month, for: source.today)?.start ?? source.today),
            calendar: HistoryCalendarViewData(weekdays: weekdays(calendar), days: days),
            selected: selection(source, entries: selectedEntries, today: today, calendar: calendar),
            todayID: String(format: "%04d-%02d-%02d", today.year, today.month, today.day),
            canUndo: source.canUndo
        )
    }

    private static func calendarDays(
        _ source: HistorySourceData, calendar: Calendar, monthStart: Date, count: Int
    ) throws -> [HistoryDayViewData?] {
        let firstWeekday = calendar.component(.weekday, from: monthStart) - calendar.firstWeekday
        let leading = (firstWeekday + 7) % 7
        let days = try (1 ... count).map { offset in
            try DiaryDay(date: calendar.date(byAdding: .day, value: offset - 1, to: monthStart) ?? monthStart,
                         timeZone: source.timeZone)
        }
        return Array(repeating: HistoryDayViewData?.none, count: leading)
            + days.map { day in
                Optional(HistoryDayViewData.viewData(
                    day: day, status: status(day, entries: source.entries, checkIns: source.checkIns),
                    timeZone: source.timeZone
                ))
            }
    }

    private static func selection(
        _ source: HistorySourceData, entries: [DiaryEntry], today: DiaryDay, calendar: Calendar
    ) throws -> HistorySelectionViewData {
        let checkIn = source.checkIns.first { $0.day == source.selectedDay }
        return try HistorySelectionViewData(
            dayID: source.selectedDay.id,
            dateLabel: date(for: source.selectedDay, calendar: calendar)
                .formatted(.dateTime.weekday(.wide).month(.wide).day().year()),
            status: status(source.selectedDay, entries: source.entries, checkIns: source.checkIns),
            entries: entries.map(TodayViewModel.row),
            checkInStatus: checkIn.map {
                String(localized: $0.coverage == .completed ? "checkIn.completed" : "checkIn.partial", bundle: .module)
            },
            canConfirmNoPoop: source.selectedDay < today && entries.isEmpty && checkIn == nil
        )
    }

    private static func weekdays(_ calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        return Array(symbols.dropFirst(calendar.firstWeekday - 1) + symbols.prefix(calendar.firstWeekday - 1))
    }

    private static func status(
        _ day: DiaryDay, entries: [DiaryEntry], checkIns: [NoPoopCheckIn]
    ) -> HistoryDayViewData.Status {
        if entries.contains(where: { DiaryDay(occurrence: $0.occurrence) == day }) {
            return .logged
        }
        guard let checkIn = checkIns.first(where: { $0.day == day }) else { return .unrecorded }
        return checkIn.coverage == .completed ? .completed : .partial
    }

    private static func gregorianCalendar(_ timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private static func date(for day: DiaryDay, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: day.year, month: day.month, day: day.day)) ?? .now
    }

    private func visibleMonthContains(_ day: DiaryDay) -> Bool {
        guard let interval = calendar().dateInterval(of: .month, for: month) else { return false }
        let dayDate = Self.date(for: day, calendar: calendar())
        return interval.contains(dayDate)
    }

    private func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone()
        return calendar
    }

    private static func monthStart(_ date: Date, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.dateInterval(of: .month, for: date)?.start ?? date
    }
}

private extension HistoryDayViewData {
    static func viewData(day: DiaryDay, status: Status, timeZone: TimeZone) -> Self {
        let dayID = day.id
        let number = String(day.day)
        var style = Date.FormatStyle.dateTime.weekday(.wide).month(.wide).day().year()
        style.timeZone = timeZone
        let date = Calendar(identifier: .gregorian).date(
            from: DateComponents(timeZone: timeZone, year: day.year, month: day.month, day: day.day)
        ) ?? .now
        let localizedStatus = String(localized: Self.statusKey(status), bundle: .module)
        let dateLabel = date.formatted(style)
        let accessibilityLabel = String(localized: "history.dateLabel \(dateLabel), \(localizedStatus)", bundle: .module)
        return Self(dayID: dayID, number: number, accessibilityLabel: accessibilityLabel, status: status)
    }

    private static func statusKey(_ status: Status) -> String.LocalizationValue {
        switch status {
        case .logged: "history.status.logged"
        case .completed: "history.status.completed"
        case .partial: "history.status.partial"
        case .unrecorded: "history.status.unrecorded"
        }
    }
}
