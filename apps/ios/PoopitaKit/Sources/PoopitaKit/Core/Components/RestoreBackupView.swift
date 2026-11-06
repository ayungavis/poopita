import DesignSystem
import SwiftUI

struct RestoreBackupView: View {
    let data: RestoreViewData
    let isWorking: Bool
    let submitKey: (String) -> Void
    let confirm: () -> Void
    let cancel: () -> Void
    @State private var typed = ""
    @FocusState private var isTyping: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl - Spacing.xs) {
                    switch data.step {
                    case let .enterKey(errorMessage):
                        keyEntry(errorMessage: errorMessage)
                    case let .preview(preview):
                        summary(preview)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xxl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColor.background)
            .navigationTitle(Text("settings.backup.restore", bundle: .module))
            .font(AppFont.body)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: cancel) {
                        Text("entry.cancel", bundle: .module)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isWorking)
        .privacySensitive()
    }

    private func keyEntry(errorMessage: String?) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("backup.restore.keyPrompt", bundle: .module)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.bottom, Spacing.sm)
            TextField(text: $typed, axis: .vertical) {
                Text(verbatim: "XXXX XXXX XXXX …")
            }
            .lineLimit(3 ... 5)
            .focused($isTyping)
            .autocorrectionDisabled()
            .keyboardCharacters()
            .padding(Spacing.lg)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
            if let errorMessage {
                Text(verbatim: errorMessage)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.destructive)
            }
            PrimaryButtonView(Text("onboarding.continue", bundle: .module)) {
                isTyping = false
                submitKey(typed)
            }
            .disabled(isWorking || typed.isEmpty)
            .padding(.top, Spacing.sm)
        }
        .onChange(of: errorMessage) { _, error in
            if let error {
                AccessibilityNotification.Announcement(error).post()
            }
        }
    }

    @ViewBuilder
    private func summary(_ preview: RestorePreviewViewData) -> some View {
        CardSectionView(nil) {
            Text(verbatim: preview.createdAt)
                .font(AppFont.body.weight(.semibold))
                .cardRow()
            CardDividerView()
            valueRow("backup.restore.logs", preview.logsToAdd)
            CardDividerView()
            valueRow("backup.restore.checkIns", preview.checkInsToAdd)
            CardDividerView()
            valueRow("backup.restore.already", preview.alreadyHere)
        }
        Text("backup.restore.merge", bundle: .module)
            .font(AppFont.caption)
            .foregroundStyle(AppColor.textSecondary)
        if let error = preview.errorMessage {
            Text(verbatim: error)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.destructive)
        }
        PrimaryButtonView(Text("backup.restore.confirm", bundle: .module), action: confirm)
            .disabled(isWorking)
    }

    private func valueRow(_ title: LocalizedStringKey, _ value: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(title, bundle: .module)
            Spacer(minLength: Spacing.md)
            Text(verbatim: value)
                .foregroundStyle(AppColor.textSecondary)
                .monospacedDigit()
        }
        .cardRow()
        .accessibilityElement(children: .combine)
    }
}

extension View {
    func restoreBackupFlow(_ backup: BackupModel, isRequested: Binding<Bool>, restored: @escaping () -> Void) -> some View {
        modifier(RestoreBackupFlow(backup: backup, isRequested: isRequested, restored: restored))
    }
}

private struct RestoreBackupFlow: ViewModifier {
    let backup: BackupModel
    @Binding var isRequested: Bool
    let restored: () -> Void
    @State private var isImporting = false

    func body(content: Content) -> some View {
        let cloudBackup = backup.state.cloudBackup
        content
            .task { await backup.refresh() }
            .confirmationDialog(
                Text("settings.backup.restore", bundle: .module),
                isPresented: Binding(get: { isRequested && cloudBackup != nil }, set: {
                    if !$0 {
                        isRequested = false
                    }
                }),
                titleVisibility: .visible
            ) {
                sources(cloudBackup: cloudBackup)
            }
            .fileImporter(
                isPresented: Binding(get: { isImporting || (isRequested && cloudBackup == nil) }, set: {
                    if !$0 {
                        isImporting = false
                        isRequested = false
                    }
                }),
                allowedContentTypes: [.poopitaBackup, .data],
                onCompletion: { result in Task { await backup.importFile(result) } }
            )
            .sheet(item: Binding(get: { backup.restore }, set: {
                if $0 == nil {
                    backup.cancelRestore()
                }
            }), content: sheet)
    }

    @ViewBuilder
    private func sources(cloudBackup: String?) -> some View {
        if let cloudBackup {
            Button {
                isRequested = false
                Task { await backup.restoreFromCloud() }
            } label: {
                Text(verbatim: cloudBackup)
            }
        }
        Button {
            isRequested = false
            isImporting = true
        } label: {
            Text("backup.restore.chooseFile", bundle: .module)
        }
    }

    private func sheet(_ data: RestoreViewData) -> some View {
        RestoreBackupView(
            data: data, isWorking: backup.isWorking, submitKey: { text in Task { await backup.submitKey(text) } },
            confirm: {
                if backup.confirmRestore() {
                    restored()
                }
            },
            cancel: { backup.cancelRestore() }
        )
    }
}
