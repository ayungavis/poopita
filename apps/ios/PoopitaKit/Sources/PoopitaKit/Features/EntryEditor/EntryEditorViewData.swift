import Foundation

struct EntryEditorViewData: Equatable, Sendable {
    let occurrenceDate: Date
    let timeZoneIdentifier: String
    let stoolType: Int?
    let amount: String?
    let effort: String?
    let note: String
}

extension EntryEditorViewData {
    func replacingDate(_ value: Date) -> Self {
        Self(occurrenceDate: value, timeZoneIdentifier: timeZoneIdentifier,
             stoolType: stoolType, amount: amount, effort: effort, note: note)
    }

    func replacingType(_ value: Int?) -> Self {
        Self(occurrenceDate: occurrenceDate, timeZoneIdentifier: timeZoneIdentifier,
             stoolType: value, amount: amount, effort: effort, note: note)
    }

    func replacingAmount(_ value: String?) -> Self {
        Self(occurrenceDate: occurrenceDate, timeZoneIdentifier: timeZoneIdentifier,
             stoolType: stoolType, amount: value, effort: effort, note: note)
    }

    func replacingEffort(_ value: String?) -> Self {
        Self(occurrenceDate: occurrenceDate, timeZoneIdentifier: timeZoneIdentifier,
             stoolType: stoolType, amount: amount, effort: value, note: note)
    }

    func replacingNote(_ value: String) -> Self {
        Self(occurrenceDate: occurrenceDate, timeZoneIdentifier: timeZoneIdentifier,
             stoolType: stoolType, amount: amount, effort: effort, note: value)
    }
}
