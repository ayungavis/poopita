import DesignSystem
import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    let reminders: RemindersViewModel
    let backup: BackupModel
    let close: () -> Void

    init(
        viewModel: SettingsViewModel, reminders: RemindersViewModel, backup: BackupModel, close: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.reminders = reminders
        self.backup = backup
        self.close = close
    }

    var body: some View {
        SettingsContentView(
            viewModel: viewModel, reminders: reminders, backup: backup, data: viewModel.state, close: close
        )
        .background(AppColor.background)
        .navigationTitle(Text("settings.title", bundle: .module))
        .largeNavigationTitle()
        .font(AppFont.body)
        .foregroundStyle(AppColor.textPrimary)
        .tint(AppColor.accent)
        .privacySensitive()
        .onAppear(perform: viewModel.refresh)
    }
}

private extension View {
    func largeNavigationTitle() -> some View {
        #if os(iOS)
            navigationBarTitleDisplayMode(.large)
        #else
            self
        #endif
    }
}
