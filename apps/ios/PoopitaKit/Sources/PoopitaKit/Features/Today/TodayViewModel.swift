import Foundation
import Observation

@MainActor
@Observable
final class TodayViewModel {
    private(set) var state: Loadable<TodayViewData> = .idle
    private(set) var composer: EntryEditorViewModel?
    private(set) var editor: EntryEditorViewModel?
    private(set) var feedback: TodayFeedbackViewData?
    private(set) var errorMessage: String?
    private(set) var loadTask: Task<Void, Never>?
    private let repository: any DiaryRepository
    private let now: () -> Date
    private let timeZone: () -> TimeZone

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
        loadTask = Task {
            do {
                try Task.checkCancellation()
                let entries = try repository.entries()
                if composer == nil || composer?.hasChanges == false {
                    composer = try makeComposer()
                }
                try Task.checkCancellation()
                state = try .loaded(Self.viewData(
                    entries: entries,
                    date: now(),
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
            composer = try makeComposer()
            feedback = TodayFeedbackViewData(id: UUID(), message: String(localized: "diary.saved", bundle: .module))
            errorMessage = nil
            load()
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }

    func savedEditor() {
        feedback = TodayFeedbackViewData(id: UUID(), message: String(localized: "diary.updated", bundle: .module))
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

    static func viewData(entries: [DiaryEntry], date: Date, timeZone: TimeZone, canUndo: Bool) throws -> TodayViewData {
        var headerStyle = Date.FormatStyle.dateTime.weekday(.wide).month(.abbreviated).day()
        headerStyle.timeZone = timeZone
        return try TodayViewData(
            dateLabel: date.formatted(headerStyle), entries: entries.map(row), canUndo: canUndo
        )
    }

    private static func row(_ entry: DiaryEntry) throws -> TodayEntryViewData {
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

    private func makeComposer() throws -> EntryEditorViewModel {
        try EntryEditorViewModel(
            repository: repository, entryID: UUID(),
            draft: EntryEditorViewData(
                occurrenceDate: now(), timeZoneIdentifier: timeZone().identifier,
                stoolType: nil, amount: nil, effort: nil, note: ""
            ), now: now
        )
    }
}
