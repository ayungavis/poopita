import DesignSystem
import SwiftUI

struct TodayContentView: View {
    let viewModel: TodayViewModel
    let data: TodayViewData
    @AccessibilityFocusState private var focusedEntry: UUID?
    @State private var editedID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                Text(verbatim: data.dateLabel).font(AppFont.body).foregroundStyle(AppColor.textSecondary)
                if let composer = viewModel.composer {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text("entry.recordTitle", bundle: .module).font(AppFont.title)
                        EntryFieldsView(viewModel: composer)
                        PrimaryButtonView(Text("entry.save", bundle: .module)) {
                            if composer.save() {
                                viewModel.savedComposer()
                            }
                        }
                    }
                    .padding(Spacing.lg)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
                    .id(composer.id)
                }
                if let checkIn = viewModel.checkIn {
                    CheckInView(viewModel: checkIn, saved: viewModel.savedCheckIn)
                }
                feedback
                Label { Text("diary.localOnly", bundle: .module) } icon: {
                    Image(systemName: "iphone.gen3")
                }
                .font(AppFont.caption).foregroundStyle(AppColor.textSecondary)
                Text("diary.entries", bundle: .module).font(AppFont.title).accessibilityAddTraits(.isHeader)
                if data.entries.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("diary.emptyTitle", bundle: .module).font(AppFont.body.weight(.semibold))
                        Text("diary.emptyDetail", bundle: .module).foregroundStyle(AppColor.textSecondary)
                    }
                    .padding(Spacing.lg)
                }
                LazyVStack(spacing: Spacing.md) {
                    ForEach(data.entries) { entry in
                        TodayEntryRowView(entry: entry) {
                            editedID = entry.id
                            viewModel.edit(id: entry.id)
                        }
                        .accessibilityFocused($focusedEntry, equals: entry.id)
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .safeAreaInset(edge: .bottom) {
            if let composer = viewModel.composer {
                PrimaryButtonView(Text("entry.save", bundle: .module)) {
                    if composer.save() {
                        viewModel.savedComposer()
                    }
                }
                .padding(Spacing.lg)
                .background(AppColor.surface)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: viewModel.feedback) { _, message in
            if let message {
                AccessibilityNotification.Announcement(message.message).post()
            }
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                AccessibilityNotification.Announcement(message).post()
            }
        }
        .sheet(item: editorBinding, onDismiss: dismissed) { editor in
            EntryEditorView(
                viewModel: editor, saved: viewModel.savedEditor,
                delete: { viewModel.delete(id: editor.id) }, deletionError: viewModel.errorMessage
            )
        }
    }

    @ViewBuilder
    private var feedback: some View {
        if let message = viewModel.feedback {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(verbatim: message.message)
                if data.canUndo {
                    Button(action: viewModel.undo) { Text("diary.undo", bundle: .module) }
                        .frame(minHeight: Spacing.touchTarget)
                }
            }
        }
        if let error = viewModel.errorMessage {
            Text(verbatim: error).foregroundStyle(AppColor.destructive)
        }
    }

    private var editorBinding: Binding<EntryEditorViewModel?> {
        Binding(get: { viewModel.editor }, set: {
            if $0 == nil {
                viewModel.dismissEditor()
            }
        })
    }

    private func dismissed() {
        viewModel.dismissEditor()
        focusedEntry = editedID
    }
}
