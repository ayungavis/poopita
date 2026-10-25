import Foundation
import Observation

@MainActor
@Observable
final class TodayViewModel {
    private(set) var state: Loadable<TodayViewData> = .idle
    private(set) var checkIn: CheckInViewModel?
    private(set) var composer: EntryEditorViewModel?
    private(set) var editor: EntryEditorViewModel?
    private(set) var feedback: TodayFeedbackViewData?
    private(set) var errorMessage: String?
    private(set) var loadTask: Task<Void, Never>?
    private let repository: any DiaryRepository
    private let now: () -> Date
    private let timeZone: () -> TimeZone
    private var selectedDay: DiaryDay?

    init(repository: any DiaryRepository, now: @escaping () -> Date, timeZone: @escaping () -> TimeZone) {
        self.repository = repository
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
                    timeZone: timeZone(),
                    canUndo: repository.canUndo
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
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone()
        guard let dayDate = calendar.date(from: DateComponents(
            timeZone: timeZone(),
            year: parts[0],
            month: parts[1],
            day: parts[2]
        )),
            let day = try? DiaryDay(date: dayDate, timeZone: timeZone()),
            day <= todayDay()
        else { return }
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
            feedback = TodayFeedbackViewData(id: UUID(), message: message)
            errorMessage = nil
            load()
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }

    func savedEditor() {
        let message = editor?.saveMessage ?? String(localized: "diary.updated", bundle: .module)
        feedback = TodayFeedbackViewData(id: UUID(), message: message)
        editor = nil
        errorMessage = nil
        load()
    }

    func savedCheckIn() {
        feedback = TodayFeedbackViewData(id: UUID(), message: String(localized: "checkIn.saved", bundle: .module))
        errorMessage = nil
        load()
    }

    @discardableResult
    func delete(id: UUID) -> Bool {
        do {
            try repository.delete(id: id)
            feedback = TodayFeedbackViewData(id: UUID(), message: String(localized: "diary.deleted", bundle: .module))
            errorMessage = nil
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
            feedback = TodayFeedbackViewData(id: UUID(), message: String(localized: "diary.undone", bundle: .module))
            errorMessage = nil
            load()
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }

    private func makeComposer() throws -> EntryEditorViewModel {
        try EntryEditorViewModel(
            repository: repository, entryID: UUID(),
            draft: EntryEditorViewData(
                occurrenceDate: now(), timeZoneIdentifier: timeZone().identifier,
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
        timeZone: TimeZone,
        canUndo: Bool
    ) throws -> TodayViewData {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = try DiaryDay(date: date, timeZone: timeZone)
        let activeDay = selectedDay ?? today

        let weekDays = try weekDayItems(
            date: date,
            activeDay: activeDay,
            entries: entries,
            checkIns: checkIns,
            timeZone: timeZone
        )

        let selectedEntries = entries.filter { DiaryDay(occurrence: $0.occurrence) == activeDay }
        let checkIn = checkIns.first { $0.day == activeDay }

        let heroStatus = heroStatusViewData(entries: selectedEntries, checkIn: checkIn, isActiveToday: activeDay == today)
        let canCheckIn = activeDay == today && selectedEntries.isEmpty && checkIn == nil

        var headerStyle = Date.FormatStyle.dateTime.weekday(.wide).month(.abbreviated).day()
        headerStyle.timeZone = timeZone
        let activeDate = calendar.date(from: DateComponents(
            timeZone: timeZone,
            year: activeDay.year,
            month: activeDay.month,
            day: activeDay.day
        )) ?? date

        return try TodayViewData(
            dateLabel: activeDate.formatted(headerStyle),
            weekDays: weekDays,
            heroStatus: heroStatus,
            canCheckInToday: canCheckIn,
            entries: selectedEntries.map(row),
            canUndo: canUndo
        )
    }

    private static func weekDayItems(
        date: Date,
        activeDay: DiaryDay,
        entries: [DiaryEntry],
        checkIns: [NoPoopCheckIn],
        timeZone: TimeZone
    ) throws -> [TodayWeekDayViewData] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            throw AppError.invalidOccurrence
        }
        let today = try DiaryDay(date: date, timeZone: timeZone)
        return try (0 ..< 7).map { offset in
            let dayDate = calendar.date(byAdding: .day, value: offset, to: weekInterval.start) ?? date
            let day = try DiaryDay(date: dayDate, timeZone: timeZone)
            let dayEntries = entries.filter { DiaryDay(occurrence: $0.occurrence) == day }
            let dayCheckIn = checkIns.first { $0.day == day }
            let hasEntries = !dayEntries.isEmpty
            let isConfirmed = dayCheckIn?.coverage == .completed
            let isPartial = dayCheckIn?.coverage == .partial
            let isToday = day == today
            let isSelected = day == activeDay
            let a11y = dayDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
            return TodayWeekDayViewData(
                dayID: day.id,
                dayNumber: "\(day.day)",
                weekdaySymbol: dayDate.formatted(.dateTime.weekday(.narrow)),
                isToday: isToday,
                isSelected: isSelected,
                hasEntries: hasEntries,
                isConfirmedNoPoop: isConfirmed,
                isPartialCheckIn: isPartial,
                accessibilityLabel: a11y
            )
        }
    }

    private static func heroStatusViewData(
        entries: [DiaryEntry], checkIn: NoPoopCheckIn?, isActiveToday: Bool
    ) -> TodayHeroStatusViewData {
        if !entries.isEmpty {
            let title = String(localized: "today.hero.logged \(entries.count)", bundle: .module)
            return TodayHeroStatusViewData(
                title: title, count: entries.count,
                isRecorded: true, isConfirmedNoPoop: false, isPartialCheckIn: false
            )
        } else if let checkIn, checkIn.coverage == .completed {
            return TodayHeroStatusViewData(
                title: String(localized: "checkIn.completed", bundle: .module), count: 0,
                isRecorded: false, isConfirmedNoPoop: true, isPartialCheckIn: false
            )
        } else if let checkIn, checkIn.coverage == .partial {
            return TodayHeroStatusViewData(
                title: String(localized: "checkIn.noneSoFar", bundle: .module), count: 0,
                isRecorded: false, isConfirmedNoPoop: false, isPartialCheckIn: true
            )
        } else {
            let title = isActiveToday
                ? String(localized: "today.hero.empty", bundle: .module)
                : String(localized: "checkIn.unknown", bundle: .module)
            return TodayHeroStatusViewData(
                title: title, count: 0,
                isRecorded: false, isConfirmedNoPoop: false, isPartialCheckIn: false
            )
        }
    }

    static func row(_ entry: DiaryEntry) throws -> TodayEntryViewData {
        guard let zone = TimeZone(secondsFromGMT: entry.occurrence.utcOffsetSeconds) else {
            throw AppError.invalidStoredData
        }
        var dateStyle = Date.FormatStyle.dateTime.year().month(.abbreviated).day()
        var timeStyle = Date.FormatStyle.dateTime.hour().minute()
        dateStyle.timeZone = zone
        timeStyle.timeZone = zone
        var observations: [String] = []
        if let type = entry.stoolType {
            guard let choice = EntryChoiceViewData.types.first(where: { $0.id == String(type) }) else {
                throw AppError.invalidStoredData
            }
            observations.append(choice.title + " · " + choice.detail)
        } else {
            observations.append(String(localized: "entry.typeSkipped", bundle: .module))
        }
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
            timeLabel: entry.occurrence.instant.formatted(timeStyle),
            observations: observations.joined(separator: " · "), note: entry.note
        )
    }
}
