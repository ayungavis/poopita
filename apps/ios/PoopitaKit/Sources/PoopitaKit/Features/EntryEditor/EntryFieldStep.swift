import Foundation

enum EntryFieldStep: CaseIterable, Hashable, Sendable {
    case type, amount, effort, blood, color, duration

    init(_ field: EntryRequiredField) {
        switch field {
        case .type: self = .type
        case .amount: self = .amount
        case .effort: self = .effort
        case .blood: self = .blood
        }
    }

    static func next(from old: EntryEditorViewData, to new: EntryEditorViewData) -> EntryFieldStep? {
        guard let picked = allCases.first(where: { $0.value(in: old) == nil && $0.value(in: new) != nil }) else {
            return nil
        }
        return allCases.drop { $0 != picked }.first { $0.value(in: new) == nil }
    }

    private func value(in draft: EntryEditorViewData) -> String? {
        switch self {
        case .type: draft.stoolType.map(String.init)
        case .amount: draft.amount
        case .effort: draft.effort
        case .blood: draft.blood
        case .color: draft.color
        case .duration: draft.duration
        }
    }
}
