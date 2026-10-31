import Foundation

enum EntryRequiredField: CaseIterable, Equatable, Sendable {
    case type, amount, effort, blood

    var title: String {
        switch self {
        case .type: String(localized: "entry.typeLabel", bundle: .module)
        case .amount: String(localized: "entry.amountLabel", bundle: .module)
        case .effort: String(localized: "entry.effortLabel", bundle: .module)
        case .blood: String(localized: "entry.bloodLabel", bundle: .module)
        }
    }

    func isMissing(in draft: EntryEditorViewData) -> Bool {
        switch self {
        case .type: draft.stoolType == nil
        case .amount: draft.amount == nil
        case .effort: draft.effort == nil
        case .blood: draft.blood == nil
        }
    }
}
