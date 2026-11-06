import DesignSystem
import SwiftUI

struct SettingsBackupView: View {
    let backup: BackupModel
    @State private var isImporting = false

    var body: some View {
        let data = backup.state
        CardSectionView("settings.backup.title", footnote: "settings.backup.footer") {
            Toggle(isOn: Binding(get: { data.isAutomatic }, set: { isOn in Task { await backup.setAutomatic(isOn) } })) {
                VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                    Text("settings.backup.automatic", bundle: .module)
                    Text(verbatim: data.automaticDetail)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .padding(.vertical, Spacing.sm)
            }
            .tint(AppColor.switchOn)
            .disabled(backup.isWorking)
            .cardRow()
            CardDividerView()
            row("settings.backup.create", detail: data.status, systemImage: "lock.doc") { Task { await backup.createBackup() } }
                .fileExporter(
                    isPresented: Binding(get: { backup.exportFile != nil }, set: {
                        if !$0 {
                            backup.finishExport(saved: false)
                        }
                    }),
                    item: backup.exportFile, contentTypes: [.poopitaBackup], defaultFilename: backup.exportFile?.fileName
                ) { result in
                    switch result {
                    case .success:
                        backup.finishExport(saved: true)
                    case let .failure(error):
                        backup.exportFailed(error)
                    }
                }
            CardDividerView()
            row("settings.backup.restore", detail: nil, systemImage: "arrow.counterclockwise") { isImporting = true }
                .restoreBackupFlow(backup, isRequested: $isImporting) {}
            if data.hasRecoveryKey {
                CardDividerView()
                row("settings.backup.key", detail: nil, systemImage: "key") { Task { await backup.showKey() } }
            }
            if let error = backup.errorMessage {
                CardDividerView()
                Text(verbatim: error)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.destructive)
                    .cardRow()
            }
        }
        .task { await backup.refresh() }
        .sheet(item: Binding(get: { backup.keySetup }, set: {
            if $0 == nil {
                backup.cancelKeySetup()
            }
        }), onDismiss: { Task { await backup.keySetupDismissed() } }, content: { setup in
            RecoveryKeySetupView(
                data: setup, isWorking: backup.isWorking, confirm: { typed in Task { await backup.confirmNewKey(typed: typed) } },
                cancel: { backup.cancelKeySetup() }
            )
        })
        .sheet(item: Binding(get: { backup.keyDisplay }, set: {
            if $0 == nil {
                backup.hideKey()
            }
        })) { key in
            RecoveryKeyView(data: key, done: { backup.hideKey() })
        }
        .sensoryFeedback(.success, trigger: data.status)
    }

    private func row(
        _ title: LocalizedStringKey, detail: String?, systemImage: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Text(title, bundle: .module)
                Spacer(minLength: Spacing.md)
                if let detail {
                    Text(verbatim: detail)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.trailing)
                }
                if backup.isWorking, title == "settings.backup.create" {
                    ProgressView()
                } else {
                    Image(systemName: systemImage)
                        .font(AppFont.caption.weight(.semibold))
                        .foregroundStyle(AppColor.textSecondary)
                        .accessibilityHidden(true)
                }
            }
            .cardRow()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(backup.isWorking)
    }
}
