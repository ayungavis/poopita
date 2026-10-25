import Foundation
import Observation

@MainActor
@Observable
final class EntryEditorViewModel: Identifiable {
    private(set) var draft: EntryEditorViewData
    private(set) var error: AppError?
    private(set) var canUndo: Bool
    private let repository: any DiaryRepository
    let id: UUID
    let displayTimeZone: TimeZone
    private let now: () -> Date
    private let initialDraft: EntryEditorViewData
    private var original: DiaryEntry?

    init(repository: any DiaryRepository, entryID: UUID, draft: EntryEditorViewData, now: @escaping () -> Date) throws {
        self.repository = repository
        id = entryID
        self.now = now
        let original = try repository.entries().first { $0.id == entryID }
        self.original = original
        let initial = original.map(Self.viewData) ?? draft
        guard let zone = TimeZone(identifier: initial.timeZoneIdentifier) else { throw AppError.invalidOccurrence }
        displayTimeZone = zone
        initialDraft = initial
        self.draft = initial
        canUndo = repository.canUndo
    }

    func updateDraft(_ draft: EntryEditorViewData) {
        self.draft = draft
        error = nil
    }

    var isEditing: Bool {
        original != nil
    }

    var hasChanges: Bool {
        draft != initialDraft
    }

    var maximumDate: Date {
        now()
    }

    var errorMessage: String? {
        error?.userMessage
    }

    func selectType(_ value: String) {
        if value == "skip" {
            setType(nil); return
        }
        guard let type = Int(value), (1 ... 7).contains(type) else {
            error = .invalidObservation
            return
        }
        setType(type)
    }

    func setDate(_ date: Date) {
        updateDraft(draft.replacingDate(date))
    }

    func setType(_ value: Int?) {
        updateDraft(draft.replacingType(value))
    }

    func setAmount(_ value: String?) {
        updateDraft(draft.replacingAmount(value))
    }

    func setEffort(_ value: String?) {
        updateDraft(draft.replacingEffort(value))
    }

    func setNote(_ value: String) {
        updateDraft(draft.replacingNote(value))
    }

    @discardableResult
    func save() -> Bool {
        defer { canUndo = repository.canUndo }
        do {
            try Task.checkCancellation()
            guard draft.occurrenceDate <= now() else { throw AppError.invalidOccurrence }
            let occurrence = try occurrence()
            let amount = draft.amount.flatMap(DiaryEntry.Amount.init(rawValue:))
            let effort = draft.effort.flatMap(DiaryEntry.Effort.init(rawValue:))
            guard draft.amount == nil || amount != nil, draft.effort == nil || effort != nil else {
                throw AppError.invalidObservation
            }
            let entry = DiaryEntry(
                id: id, occurrence: occurrence, stoolType: draft.stoolType,
                amount: amount, effort: effort, note: draft.note
            )
            try repository.save(entry)
            original = entry
            error = nil
            return true
        } catch is CancellationError {
            return false
        } catch {
            self.error = AppError(wrapping: error)
            Log.report(error, context: Log.Context(operation: "diary.save"))
            return false
        }
    }

    static func viewData(for entry: DiaryEntry) -> EntryEditorViewData {
        EntryEditorViewData(
            occurrenceDate: entry.occurrence.instant, timeZoneIdentifier: entry.occurrence.timeZoneIdentifier,
            stoolType: entry.stoolType, amount: entry.amount?.rawValue, effort: entry.effort?.rawValue, note: entry.note
        )
    }

    private func occurrence() throws -> OccurrenceTime {
        let unchanged = original?.occurrence.instant == draft.occurrenceDate
            && original?.occurrence.timeZoneIdentifier == draft.timeZoneIdentifier
        if let original, unchanged {
            return original.occurrence
        }
        guard let zone = TimeZone(identifier: draft.timeZoneIdentifier) else { throw AppError.invalidOccurrence }
        return try OccurrenceTime(instant: draft.occurrenceDate, timeZone: zone)
    }
}
