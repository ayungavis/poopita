import DesignSystem
import SwiftUI

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: EntryEditorViewModel
    @State private var confirmDiscard = false
    @State private var confirmDelete = false
    @AccessibilityFocusState private var summaryFocused: Bool
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
        VStack(spacing: 0) {
            EntryEditorHeaderView(viewModel: viewModel, close: close)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        EntryFieldsView(viewModel: viewModel)
                        if viewModel.isEditing {
                            Button { confirmDelete = true } label: {
                                Text("entry.delete", bundle: .module)
                                    .font(AppFont.body.weight(.medium)).foregroundStyle(AppColor.destructive)
                                    .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
                            }
                        }
                        if let deletionError {
                            Text(verbatim: deletionError).foregroundStyle(AppColor.destructive)
                        }
                    }
                    .padding(Spacing.xl)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: viewModel.missingFields) { _, missing in
                    guard let first = missing.first else { return }
                    withAnimation { proxy.scrollTo(EntryFieldStep(first), anchor: .top) }
                    summaryFocused = true
                }
                .onChange(of: viewModel.draft) { old, new in
                    guard let next = EntryFieldStep.next(from: old, to: new) else { return }
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35).delay(0.15)) {
                        proxy.scrollTo(next, anchor: .top)
                    }
                }
            }
            saveBar
        }
        .background(AppColor.background)
        .sensoryFeedback(.error, trigger: viewModel.missingFields) { _, missing in !missing.isEmpty }
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
        .tint(AppColor.accent)
        .privacySensitive()
    }

    private var saveBar: some View {
        VStack(spacing: Spacing.sm) {
            if let summary = viewModel.missingSummary {
                Text(verbatim: summary)
                    .font(AppFont.caption.weight(.medium)).foregroundStyle(AppColor.destructive)
                    .accessibilityFocused($summaryFocused)
            }
            if let error = viewModel.errorMessage {
                Text(verbatim: error).font(AppFont.caption).foregroundStyle(AppColor.destructive)
            }
            PrimaryButtonView(Text(viewModel.isEditing ? "entry.saveChanges" : "entry.saveLog", bundle: .module)) {
                if viewModel.save() {
                    saved()
                    dismiss()
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.md)
        .background(AppColor.background)
        .overlay(alignment: .top) { AppColor.hairline.frame(height: Spacing.borderWidth) }
    }

    private func close() {
        if viewModel.hasChanges {
            confirmDiscard = true
        } else {
            dismiss()
        }
    }
}
