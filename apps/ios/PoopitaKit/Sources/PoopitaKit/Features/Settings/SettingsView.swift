import DesignSystem
import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    let reminders: RemindersViewModel

    init(viewModel: SettingsViewModel, reminders: RemindersViewModel) {
        _viewModel = State(initialValue: viewModel)
        self.reminders = reminders
    }

    var body: some View {
        SettingsContentView(viewModel: viewModel, reminders: reminders, data: viewModel.state)
            .background(AppColor.background)
            .navigationTitle(Text("settings.title", bundle: .module))
            .largeNavigationTitle()
            .font(AppFont.body)
            .foregroundStyle(AppColor.textPrimary)
            .tint(AppColor.accent)
            .privacySensitive()
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
