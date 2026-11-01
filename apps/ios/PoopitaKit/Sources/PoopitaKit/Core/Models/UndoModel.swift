import Foundation
import Observation

@MainActor
@Observable
final class UndoModel {
    private(set) var toast: UndoToastViewData?
    private(set) var revision = 0
    private let repository: any DiaryRepository

    init(repository: any DiaryRepository) {
        self.repository = repository
    }

    func record(_ message: String, undoable: Bool = true) {
        toast = UndoToastViewData(
            id: UUID(), message: message, canUndo: undoable && repository.canUndo, staysUntilDismissed: false
        )
    }

    func undo() {
        do {
            try repository.undo()
            revision += 1
            toast = UndoToastViewData(
                id: UUID(), message: String(localized: "diary.undone", bundle: .module), canUndo: false,
                staysUntilDismissed: false
            )
        } catch {
            Log.report(error, context: Log.Context(operation: "diary.undo"))
            toast = UndoToastViewData(
                id: UUID(), message: AppError(wrapping: error).userMessage, canUndo: false, staysUntilDismissed: true
            )
        }
    }

    func dismiss(id: UUID) {
        if toast?.id == id {
            toast = nil
        }
    }
}
