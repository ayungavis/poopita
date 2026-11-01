import Foundation

struct UndoToastViewData: Equatable, Sendable, Identifiable {
    let id: UUID
    let message: String
    let canUndo: Bool
    let staysUntilDismissed: Bool
}
