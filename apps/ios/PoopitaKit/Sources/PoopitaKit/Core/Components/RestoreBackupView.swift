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
    func restoreBackupFlow(_ backup: BackupModel, isImporting: Binding<Bool>, restored: @escaping () -> Void) -> some View {
        fileImporter(isPresented: isImporting, allowedContentTypes: [.poopitaBackup, .data]) { result in
            Task { await backup.importFile(result) }
        }
        .sheet(item: Binding(get: { backup.restore }, set: {
            if $0 == nil {
                backup.cancelRestore()
            }
        })) { data in
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
}
