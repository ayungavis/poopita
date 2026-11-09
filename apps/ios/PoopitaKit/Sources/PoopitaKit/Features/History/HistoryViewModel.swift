import Foundation
import Observation

@MainActor
@Observable
final class HistoryViewModel {
    private(set) var state: Loadable<HistoryViewData> = .idle
    private var selectedDay: DiaryDay
    private(set) var editor: EntryEditorViewModel?
    private(set) var errorMessage: String?
    private let repository: any DiaryRepository
    private let undoModel: UndoModel
    private let now: () -> Date
    private let timeZone: () -> TimeZone
    private var month: Date

    init(
        repository: any DiaryRepository, undoModel: UndoModel, now: @escaping () -> Date,
        timeZone: @escaping () -> TimeZone
    ) throws {
        self.repository = repository
        self.undoModel = undoModel
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
                selectedDay: selectedDay, today: now(), timeZone: timeZone()
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

    func open(id: String) {
        guard let day = Self.day(id: id), (try? day.validate()) != nil, day <= todayDay() else { return }
        selectedDay = day
        month = Self.monthStart(Self.date(for: day, calendar: calendar()), timeZone: timeZone())
        load()
    }

    private static func day(id: String) -> DiaryDay? {
        let parts = id.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return DiaryDay(year: parts[0], month: parts[1], day: parts[2])
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
        undoModel.record(editor?.saveMessage ?? String(localized: "diary.saved", bundle: .module))
        editor = nil
        load()
    }

    func delete(id: UUID) -> Bool {
        do {
            try repository.delete(id: id)
            undoModel.record(String(localized: "diary.deleted", bundle: .module))
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
            undoModel.record(String(localized: "checkIn.saved", bundle: .module))
            load()
            return true
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
            return false
        }
    }

    private func todayDay() -> DiaryDay {
        (try? DiaryDay(date: now(), timeZone: timeZone())) ?? selectedDay
    }

    static func viewData(_ source: HistorySourceData) throws -> HistoryViewData {
        let calendar = TodayViewModel.calendar(source.timeZone)
        guard let monthStart = calendar.dateInterval(of: .month, for: source.month)?.start,
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart)
        else { throw AppError.invalidOccurrence }
        let today = try DiaryDay(date: source.today, timeZone: source.timeZone)
        let marks = DayMarks(entries: source.entries, checkIns: source.checkIns, today: today)
        let logs = marks.logs
        let days = try (1 ... monthRange.count).map { offset in
            try DiaryDay(date: calendar.date(byAdding: .day, value: offset - 1, to: monthStart) ?? monthStart,
                         timeZone: source.timeZone)
        }
        let leading = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        let cells = days.map { day in
            HistoryDayViewData.viewData(
                day: day, mark: marks.mark(day), today: today, selected: source.selectedDay, timeZone: source.timeZone
            )
        }
        var monthStyle = Date.FormatStyle.dateTime.month(.wide)
        monthStyle.timeZone = source.timeZone
        let monthName = monthStart.formatted(monthStyle)
        let monthLogs = days.reduce(0) { $0 + (logs[$1]?.count ?? 0) }
        let unrecorded = cells.filter { $0.mark == .unrecorded }
        return try HistoryViewData(
            monthLabel: monthStart.formatted(.dateTime.month(.wide).year()),
            monthName: monthName,
            yearLabel: monthStart.formatted(.dateTime.year()),
            canMoveNext: monthStart < (calendar.dateInterval(of: .month, for: source.today)?.start ?? source.today),
            calendar: HistoryCalendarViewData(
                weekdays: weekdays(calendar), days: Array(repeating: nil, count: leading) + cells
            ),
            logSummary: monthLogs == 1 ? String(localized: "history.monthLogs.one \(monthName)", bundle: .module)
                : String(localized: "history.monthLogs \(monthLogs) \(monthName)", bundle: .module),
            unrecorded: unrecorded.first.map {
                HistoryUnrecordedViewData(dayID: $0.dayID, label: unrecordedLabel(unrecorded.count))
            },
            selected: selection(source, logs: logs[source.selectedDay] ?? [], today: today, calendar: calendar),
            isShowingToday: source.selectedDay == today
        )
    }

    private static func unrecordedLabel(_ count: Int) -> String {
        count == 1 ? String(localized: "history.unrecordedDays.one", bundle: .module)
            : String(localized: "history.unrecordedDays \(count)", bundle: .module)
    }

    private static func selection(
        _ source: HistorySourceData, logs: [DiaryEntry], today: DiaryDay, calendar: Calendar
    ) throws -> HistorySelectionViewData {
        let selected = source.selectedDay
        let date = try TodayViewModel.start(of: selected, calendar: calendar)
        var dateStyle = Date.FormatStyle.dateTime.weekday(.wide).day().month(.wide)
        var weekdayStyle = Date.FormatStyle.dateTime.weekday(.wide)
        var shortWeekdayStyle = Date.FormatStyle.dateTime.weekday(.abbreviated)
        dateStyle.timeZone = source.timeZone
        weekdayStyle.timeZone = source.timeZone
        shortWeekdayStyle.timeZone = source.timeZone
        let logLabel = String(localized: "today.logFor \(date.formatted(weekdayStyle))", bundle: .module)
        let content: HistorySelectionViewData.Content
        if !logs.isEmpty {
            let rows = try logs.sorted { $0.occurrence.instant < $1.occurrence.instant }.map(TodayViewModel.row)
            content = .entries(rows, logLabel: logLabel)
        } else if selected < today, case let .pastDay(status, detail, label, canConfirm, mark) = try TodayViewModel.dayState(
            hasLogs: false, latestEntry: nil, checkIn: source.checkIns.first { $0.day == selected },
            pastWeekday: date.formatted(shortWeekdayStyle), now: source.today
        ) {
            content = .pastDay(status: status, detail: detail, logLabel: label, canConfirm: canConfirm, mark: mark)
        } else {
            content = .open(logLabel: logLabel)
        }
        return HistorySelectionViewData(
            dayID: selected.id,
            dateLabel: date.formatted(dateStyle),
            countLabel: logs.isEmpty ? nil : TodayViewModel.logCount(logs.count),
            content: content
        )
    }

    static func weekdays(_ calendar: Calendar, locale: Locale = .current) -> [String] {
        var localized = calendar
        localized.locale = locale
        let symbols = localized.veryShortStandaloneWeekdaySymbols
        return Array(symbols.dropFirst(calendar.firstWeekday - 1) + symbols.prefix(calendar.firstWeekday - 1))
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
    static func viewData(
        day: DiaryDay, mark: DayMarkViewData, today: DiaryDay, selected: DiaryDay, timeZone: TimeZone
    ) -> Self {
        var style = Date.FormatStyle.dateTime.weekday(.wide).day().month(.wide)
        style.timeZone = timeZone
        let date = Calendar(identifier: .gregorian).date(
            from: DateComponents(timeZone: timeZone, year: day.year, month: day.month, day: day.day)
        ) ?? .now
        let label = [date.formatted(style), statusLabel(mark)].compactMap(\.self).joined(separator: ", ")
        return Self(
            dayID: day.id, number: String(day.day), accessibilityLabel: label, mark: mark,
            isToday: day == today, isSelected: day == selected
        )
    }

    private static func statusLabel(_ mark: DayMarkViewData) -> String? {
        switch mark {
        case let .logs(count): TodayViewModel.logCount(count)
        case .noPoop: String(localized: "checkIn.completed", bundle: .module)
        case .unrecorded: String(localized: "checkIn.unknown", bundle: .module)
        case .untracked, .future, .open: nil
        }
    }
}
