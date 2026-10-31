import Foundation

struct EntryEditorViewData: Equatable, Sendable {
    var occurrenceDate: Date
    var timeZoneIdentifier: String
    var stoolType: Int?
    var amount: String?
    var effort: String?
    var blood: String?
    var color: String?
    var duration: String?
    var note: String
}

extension EntryEditorViewData {
    func replacing<Value>(_ field: WritableKeyPath<Self, Value>, with value: Value) -> Self {
        var copy = self
        copy[keyPath: field] = value
        return copy
    }
}
