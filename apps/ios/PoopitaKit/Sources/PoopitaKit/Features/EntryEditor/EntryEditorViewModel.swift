import Foundation
import Observation

@MainActor
@Observable
final class EntryEditorViewModel: Identifiable {
    private(set) var draft: EntryEditorViewData
    private(set) var error: AppError?
    private(set) var saveMessage: String?
    private(set) var canUndo: Bool
    private(set) var attemptedSave = false
    private let repository: any DiaryRepository
    let id: UUID
    let displayTimeZone: TimeZone
    private let now: () -> Date
    private let initialDraft: EntryEditorViewData
    private var original: DiaryEntry?
    private let previous: EntryEditorViewData?

    init(repository: any DiaryRepository, entryID: UUID, draft: EntryEditorViewData, now: @escaping () -> Date) throws {
        self.repository = repository
        id = entryID
        self.now = now
        let entries = try repository.entries()
        let original = entries.first { $0.id == entryID }
        self.original = original
        previous = original == nil ? Self.previousComplete(in: entries) : nil
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

    var whenLabels: (date: String, time: String) {
        Self.whenLabels(for: draft.occurrenceDate, now: now(), timeZone: displayTimeZone, locale: .current)
    }

    var errorMessage: String? {
        error?.userMessage
    }

    var missingFields: [EntryRequiredField] {
        guard attemptedSave else { return [] }
        return EntryRequiredField.allCases.filter { $0.isMissing(in: draft) }
    }

    var missingSummary: String? {
        let names = missingFields.map(\.title)
        guard !names.isEmpty else { return nil }
        return String(localized: "entry.missing \(names.formatted(.list(type: .and)))", bundle: .module)
    }

    var repeatSummary: String? {
        Self.repeatSummary(previous: previous, draft: draft)
    }

    func repeatLastTime() {
        guard let previous else { return }
        updateDraft(Self.repeating(previous, onto: draft))
    }

    func selectType(_ value: String) {
        guard let type = Int(value), (1 ... 7).contains(type) else {
            error = .invalidObservation
            return
        }
        setType(draft.stoolType == type ? nil : type)
    }

    func setDate(_ date: Date) {
        updateDraft(draft.replacing(\.occurrenceDate, with: date))
    }

    func setType(_ value: Int?) {
        updateDraft(draft.replacing(\.stoolType, with: value))
    }

    func setAmount(_ value: String?) {
        updateDraft(draft.replacing(\.amount, with: toggled(value, from: draft.amount)))
    }

    func setEffort(_ value: String?) {
        updateDraft(draft.replacing(\.effort, with: toggled(value, from: draft.effort)))
    }

    func setBlood(_ value: String?) {
        updateDraft(draft.replacing(\.blood, with: toggled(value, from: draft.blood)))
    }

    func setColor(_ value: String?) {
        updateDraft(draft.replacing(\.color, with: toggled(value, from: draft.color)))
    }

    func setDuration(_ value: String?) {
        updateDraft(draft.replacing(\.duration, with: toggled(value, from: draft.duration)))
    }

    func setNote(_ value: String) {
        updateDraft(draft.replacing(\.note, with: value))
    }

    func hasSuggestion(_ phrase: String) -> Bool {
        NoteSuggestions.contains(phrase, in: draft.note)
    }

    func toggleSuggestion(_ phrase: String) {
        setNote(NoteSuggestions.toggling(phrase, in: draft.note))
    }

    @discardableResult
    func save() -> Bool {
        defer { canUndo = repository.canUndo }
        attemptedSave = true
        guard missingFields.isEmpty else { return false }
        do {
            try Task.checkCancellation()
            guard draft.occurrenceDate <= now() else { throw AppError.invalidOccurrence }
            let entry = try makeEntry()
            let result = try repository.save(entry)
            saveMessage = result == .dayUpdated
                ? String(localized: "diary.dayUpdated", bundle: .module)
                : isEditing ? String(localized: "diary.updated", bundle: .module)
                : String(localized: "diary.saved", bundle: .module)
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
            stoolType: entry.stoolType, amount: entry.amount?.rawValue, effort: entry.effort?.rawValue,
            blood: entry.blood?.rawValue, color: entry.color?.rawValue, duration: entry.duration?.rawValue,
            note: entry.note
        )
    }

    static func previousComplete(in entries: [DiaryEntry]) -> EntryEditorViewData? {
        entries.first { $0.stoolType != nil && $0.amount != nil && $0.effort != nil && $0.blood != nil }
            .map(viewData)
    }

    static func repeating(_ previous: EntryEditorViewData, onto draft: EntryEditorViewData) -> EntryEditorViewData {
        var draft = draft
        draft.stoolType = previous.stoolType
        draft.amount = previous.amount
        draft.effort = previous.effort
        draft.blood = previous.blood
        return draft
    }

    static func repeatSummary(previous: EntryEditorViewData?, draft: EntryEditorViewData) -> String? {
        guard let previous, repeating(previous, onto: draft) != draft else { return nil }
        let titles = [
            EntryChoiceViewData.types.first { $0.id == previous.stoolType.map(String.init) },
            EntryChoiceViewData.amounts.first { $0.id == previous.amount },
            EntryChoiceViewData.efforts.first { $0.id == previous.effort },
            EntryChoiceViewData.bloods.first { $0.id == previous.blood },
        ].compactMap { $0?.title }
        return titles.formatted(.list(type: .and, width: .narrow))
    }

    static func whenLabels(
        for date: Date, now: Date, timeZone: TimeZone, locale: Locale
    ) -> (date: String, time: String) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let style = Date.FormatStyle(locale: locale, timeZone: timeZone)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let day = if calendar.isDate(date, inSameDayAs: now) {
            String(localized: "diary.today", bundle: .module)
        } else if calendar.isDate(date, inSameDayAs: yesterday) {
            String(localized: "entry.yesterday", bundle: .module)
        } else {
            date.formatted(style.weekday(.abbreviated).month(.abbreviated).day())
        }
        return (day, date.formatted(style.hour().minute()))
    }

    private func makeEntry() throws -> DiaryEntry {
        let amount = draft.amount.flatMap(DiaryEntry.Amount.init(rawValue:))
        let effort = draft.effort.flatMap(DiaryEntry.Effort.init(rawValue:))
        let blood = draft.blood.flatMap(DiaryEntry.Blood.init(rawValue:))
        let color = draft.color.flatMap(DiaryEntry.StoolColor.init(rawValue:))
        let duration = draft.duration.flatMap(DiaryEntry.Duration.init(rawValue:))
        guard draft.amount == nil || amount != nil, draft.effort == nil || effort != nil,
              draft.blood == nil || blood != nil, draft.color == nil || color != nil,
              draft.duration == nil || duration != nil
        else {
            throw AppError.invalidObservation
        }
        return try DiaryEntry(
            id: id, occurrence: occurrence(), stoolType: draft.stoolType, amount: amount, effort: effort,
            blood: blood, color: color, duration: duration, note: draft.note
        )
    }

    private func toggled(_ value: String?, from current: String?) -> String? {
        value == current ? nil : value
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
