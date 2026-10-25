import DesignSystem
import SwiftUI

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EntryEditorViewModel
    @State private var confirmDiscard = false
    @State private var confirmDelete = false
    let saved: () -> Void
    let delete: () -> Bool
    let deletionError: String?

    init(viewModel: EntryEditorViewModel, saved: @escaping () -> Void, delete: @escaping () -> Bool, deletionError: String?) {
        _viewModel = State(initialValue: viewModel)
        self.saved = saved
        self.delete = delete
        self.deletionError = deletionError
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    EntryFieldsView(viewModel: viewModel)
                    if let deletionError {
                        Text(verbatim: deletionError).foregroundStyle(AppColor.destructive)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(AppColor.background)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                PrimaryButtonView(Text("entry.saveChanges", bundle: .module)) {
                    if viewModel.save() {
                        saved()
                        dismiss()
                    }
                }
                .padding(Spacing.lg)
                .background(AppColor.surface)
            }
            .navigationTitle(Text("entry.editTitle", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { close() } label: { Text("entry.cancel", bundle: .module) }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Text("entry.delete", bundle: .module)
                    }
                }
            }
            .interactiveDismissDisabled(viewModel.hasChanges)
            .confirmationDialog(Text("entry.discardQuestion", bundle: .module), isPresented: $confirmDiscard) {
                Button(role: .destructive) { dismiss() } label: { Text("entry.discard", bundle: .module) }
                Button(role: .cancel) {} label: { Text("entry.keepEditing", bundle: .module) }
            }
            .confirmationDialog(Text("entry.deleteQuestion", bundle: .module), isPresented: $confirmDelete) {
                Button(role: .destructive) {
                    if delete() {
                        dismiss()
                    }
                } label: {
                    Text("entry.delete", bundle: .module)
                }
                Button(role: .cancel) {} label: { Text("entry.cancel", bundle: .module) }
            }
        }
        .tint(AppColor.accent)
        .privacySensitive()
    }

    private func close() {
        if viewModel.hasChanges {
            confirmDiscard = true
        } else {
            dismiss()
        }
    }
}
