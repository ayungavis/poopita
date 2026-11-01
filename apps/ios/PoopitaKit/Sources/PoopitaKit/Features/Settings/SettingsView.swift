import DesignSystem
import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    let reminders: RemindersViewModel
    let close: () -> Void

    init(viewModel: SettingsViewModel, reminders: RemindersViewModel, close: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.reminders = reminders
        self.close = close
    }

    var body: some View {
        SettingsContentView(viewModel: viewModel, reminders: reminders, data: viewModel.state, close: close)
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
