import Foundation
import Observation

@MainActor
@Observable
final class TodayViewModel {
    private(set) var state: Loadable<TodayViewData> = .idle
    private(set) var checkIn: CheckInViewModel?
    private(set) var composer: EntryEditorViewModel?
    private(set) var editor: EntryEditorViewModel?
    private(set) var errorMessage: String?
    private(set) var loadTask: Task<Void, Never>?
    private let repository: any DiaryRepository
    private let undoModel: UndoModel
    private let now: () -> Date
    private let timeZone: () -> TimeZone
    private var selectedDay: DiaryDay?

    init(
        repository: any DiaryRepository, undoModel: UndoModel, now: @escaping () -> Date,
        timeZone: @escaping () -> TimeZone
    ) {
        self.repository = repository
        self.undoModel = undoModel
        self.now = now
        self.timeZone = timeZone
    }

    func load() {
        loadTask?.cancel()
        if case .loaded = state {} else {
            state = .loading
        }
        let targetDay = selectedDay ?? todayDay()
        loadTask = Task {
            do {
                try Task.checkCancellation()
                let entries = try repository.entries()
                let checkIns = try repository.checkIns()
                if checkIn == nil {
                    checkIn = try CheckInViewModel(repository: repository, now: now, timeZone: timeZone)
                }
                try checkIn?.load()
                if composer == nil || composer?.hasChanges == false {
                    composer = try makeComposer()
                }
                try Task.checkCancellation()
                state = try .loaded(Self.viewData(
                    entries: entries,
                    checkIns: checkIns,
                    date: now(),
                    selectedDay: targetDay,
                    timeZone: timeZone()
                ))
            } catch is CancellationError {
            } catch {
                Log.report(error, context: Log.Context(operation: "diary.load"))
                state = .failed(AppError(wrapping: error))
            }
        }
    }

    func selectDay(id: String) {
        let parts = id.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return }
        let day = DiaryDay(year: parts[0], month: parts[1], day: parts[2])
        guard (try? day.validate()) != nil, day <= todayDay() else { return }
        selectedDay = day
        load()
    }

    func presentLogSheet() {
        do {
            if composer == nil || composer?.hasChanges == false {
                composer = try makeComposer()
            }
            editor = composer
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }

    func presentLogForSelectedDay() {
        guard let day = selectedDay, day < todayDay() else {
            presentLogSheet()
            return
        }
        do {
            let calendar = Self.calendar(timeZone())
            let start = try Self.start(of: day, calendar: calendar)
            let elapsedToday = now().timeIntervalSince(calendar.startOfDay(for: now()))
            if composer == nil || composer?.hasChanges == false {
                composer = try makeComposer(at: start.addingTimeInterval(elapsedToday))
            }
            editor = composer
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }

    func confirmNoPoopForSelectedDay() {
        guard let checkIn, let day = selectedDay, day < todayDay() else { return }
        do {
            try checkIn.selectDate(Self.start(of: day, calendar: Self.calendar(timeZone())))
            if checkIn.confirmSelectedDay() {
                savedCheckIn()
            } else {
                errorMessage = checkIn.errorMessage
            }
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }

    func recordCheckInToday() {
        guard let checkIn else { return }
        if checkIn.recordToday() {
            savedCheckIn()
        }
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

    func dismissEditor() {
        editor = nil
    }

    func savedComposer() {
        do {
            let message = composer?.saveMessage ?? String(localized: "diary.saved", bundle: .module)
            composer = try makeComposer()
            editor = nil
            undoModel.record(message)
            errorMessage = nil
            load()
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }

    func savedEditor() {
        let message = editor?.saveMessage ?? String(localized: "diary.updated", bundle: .module)
        undoModel.record(message)
        editor = nil
        errorMessage = nil
        load()
    }

    func savedCheckIn() {
        undoModel.record(String(localized: "checkIn.saved", bundle: .module))
        errorMessage = nil
        load()
    }

    @discardableResult
    func delete(id: UUID) -> Bool {
        do {
            try repository.delete(id: id)
            undoModel.record(String(localized: "diary.deleted", bundle: .module))
            errorMessage = nil
            load()
            return true
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
            return false
        }
    }

    @discardableResult
    func move(id: UUID, toMinute minute: Int) -> Bool {
        do {
            guard let entry = try repository.entries().first(where: { $0.id == id }) else { throw AppError.notFound }
            let date = try dateOnSelectedDay(minute: minute)
            guard date <= now() else { throw AppError.invalidOccurrence }
            try repository.save(DiaryEntry(
                id: entry.id, occurrence: OccurrenceTime(instant: date, timeZone: timeZone()),
                stoolType: entry.stoolType, amount: entry.amount, effort: entry.effort, blood: entry.blood,
                color: entry.color, duration: entry.duration, note: entry.note
            ))
            undoModel.record(String(localized: "today.moved \(timeLabel(minuteOfDay: minute))", bundle: .module))
            errorMessage = nil
            load()
            return true
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
            return false
        }
    }

    func timeLabel(minuteOfDay minute: Int) -> String {
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.timeZone = timeZone()
        return (try? dateOnSelectedDay(minute: minute).formatted(style)) ?? ""
    }

    private func dateOnSelectedDay(minute: Int) throws -> Date {
        let calendar = Self.calendar(timeZone())
        let start = try Self.start(of: selectedDay ?? todayDay(), calendar: calendar)
        guard let date = calendar.date(byAdding: .minute, value: minute, to: start) else {
            throw AppError.invalidOccurrence
        }
        return date
    }

    private func makeComposer(at date: Date? = nil) throws -> EntryEditorViewModel {
        try EntryEditorViewModel(
            repository: repository, entryID: UUID(),
            draft: EntryEditorViewData(
                occurrenceDate: date ?? now(), timeZoneIdentifier: timeZone().identifier,
                stoolType: nil, amount: nil, effort: nil, note: ""
            ), now: now
        )
    }

    private func todayDay() -> DiaryDay {
        if let day = try? DiaryDay(date: now(), timeZone: timeZone()) {
            return day
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone()
        let components = calendar.dateComponents(in: timeZone(), from: now())
        let year = components.year ?? 2026
        let month = components.month ?? 10
        let day = components.day ?? 20
        return (try? DiaryDay(
            date: calendar.date(from: DateComponents(timeZone: timeZone(), year: year, month: month, day: day)) ?? now(),
            timeZone: timeZone()
        )) ?? DiaryDay(year: year, month: month, day: day)
    }
}

extension TodayViewModel {
    static func viewData(
        entries: [DiaryEntry],
        checkIns: [NoPoopCheckIn] = [],
        date: Date,
        selectedDay: DiaryDay? = nil,
        timeZone: TimeZone
    ) throws -> TodayViewData {
        let calendar = calendar(timeZone)
        let today = try DiaryDay(date: date, timeZone: timeZone)
        let activeDay = selectedDay ?? today
        let activeDate = try start(of: activeDay, calendar: calendar)
        let weekDays = try weekDayItems(
            date: date, activeDay: activeDay, entries: entries, checkIns: checkIns, calendar: calendar
        )
        let dayEntries = entries
            .filter { DiaryDay(occurrence: $0.occurrence) == activeDay }
            .sorted { $0.occurrence.instant < $1.occurrence.instant }
        let latestEntry = entries.max { $0.occurrence.instant < $1.occurrence.instant }
        let fillIn = weekDays.first { $0.mark == .unrecorded && !$0.isSelected }.map {
            TodayFillInViewData(dayID: $0.dayID, label: String(localized: "today.fillIn \($0.weekdayName)", bundle: .module))
        }

        var monthStyle = Date.FormatStyle.dateTime.month(.wide).year()
        monthStyle.timeZone = timeZone
        var weekdayStyle = Date.FormatStyle.dateTime.weekday(.wide)
        weekdayStyle.timeZone = timeZone
        var shortWeekdayStyle = Date.FormatStyle.dateTime.weekday(.abbreviated)
        shortWeekdayStyle.timeZone = timeZone

        return try TodayViewData(
            monthLabel: activeDate.formatted(monthStyle),
            title: activeDay == today ? String(localized: "diary.today", bundle: .module)
                : activeDate.formatted(weekdayStyle),
            weekDays: weekDays.map(\.item),
            sinceLastLog: sinceLastLog(latestEntry?.occurrence.instant, now: date, calendar: calendar),
            fillIn: fillIn,
            dayState: dayState(
                hasLogs: !dayEntries.isEmpty,
                latestEntry: latestEntry,
                checkIn: checkIns.first { $0.day == activeDay },
                pastWeekday: activeDay == today ? nil : activeDate.formatted(shortWeekdayStyle),
                now: date
            ),
            timeline: timeline(
                dayEntries: dayEntries, isToday: activeDay == today, now: date,
                activeDate: activeDate, calendar: calendar
            )
        )
    }

    nonisolated static func logCount(_ count: Int) -> String {
        count == 1 ? String(localized: "today.logCount.one", bundle: .module)
            : String(localized: "today.logCount \(count)", bundle: .module)
    }

    nonisolated static func calendar(_ timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = 2
        return calendar
    }

    nonisolated static func start(of day: DiaryDay, calendar: Calendar) throws -> Date {
        guard let date = calendar.date(from: DateComponents(year: day.year, month: day.month, day: day.day)) else {
            throw AppError.invalidOccurrence
        }
        return date
    }

    private struct WeekDay {
        let item: TodayWeekDayViewData
        let weekdayName: String
        var mark: DayMarkViewData {
            item.mark
        }

        var dayID: String {
            item.dayID
        }

        var isSelected: Bool {
            item.isSelected
        }
    }

    private static func weekDayItems(
        date: Date,
        activeDay: DiaryDay,
        entries: [DiaryEntry],
        checkIns: [NoPoopCheckIn],
        calendar: Calendar
    ) throws -> [WeekDay] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            throw AppError.invalidOccurrence
        }
        let today = try DiaryDay(date: date, timeZone: calendar.timeZone)
        var labelStyle = Date.FormatStyle.dateTime.weekday(.wide).month(.abbreviated).day()
        var symbolStyle = Date.FormatStyle.dateTime.weekday(.narrow)
        var nameStyle = Date.FormatStyle.dateTime.weekday(.wide)
        labelStyle.timeZone = calendar.timeZone
        symbolStyle.timeZone = calendar.timeZone
        nameStyle.timeZone = calendar.timeZone
        return try (0 ..< 7).map { offset in
            let dayDate = calendar.date(byAdding: .day, value: offset, to: weekInterval.start) ?? date
            let day = try DiaryDay(date: dayDate, timeZone: calendar.timeZone)
            let logs = entries.count { DiaryDay(occurrence: $0.occurrence) == day }
            let coverage = checkIns.first { $0.day == day }?.coverage
            let mark: DayMarkViewData = if logs > 0 {
                .logs(logs)
            } else if coverage == .completed {
                .noPoop
            } else if coverage == .partial {
                .noneSoFar
            } else if day > today {
                .future
            } else if day == today {
                .open
            } else {
                .unrecorded
            }
            let label = [dayDate.formatted(labelStyle), markLabel(mark)].compactMap(\.self).joined(separator: ", ")
            return WeekDay(
                item: TodayWeekDayViewData(
                    dayID: day.id,
                    dayNumber: "\(day.day)",
                    weekdaySymbol: dayDate.formatted(symbolStyle),
                    isToday: day == today,
                    isSelected: day == activeDay,
                    mark: mark,
                    accessibilityLabel: label
                ),
                weekdayName: dayDate.formatted(nameStyle)
            )
        }
    }

    private static func markLabel(_ mark: DayMarkViewData) -> String? {
        switch mark {
        case let .logs(count): logCount(count)
        case .noPoop: String(localized: "checkIn.completed", bundle: .module)
        case .noneSoFar: String(localized: "checkIn.partial", bundle: .module)
        case .unrecorded: String(localized: "checkIn.unknown", bundle: .module)
        case .untracked, .future, .open: nil
        }
    }
}
