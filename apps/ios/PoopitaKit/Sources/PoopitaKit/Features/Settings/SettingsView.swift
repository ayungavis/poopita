import DesignSystem
import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        SettingsContentView(viewModel: viewModel, data: viewModel.state)
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
