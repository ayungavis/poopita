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
            .font(AppFont.body)
            .foregroundStyle(AppColor.textPrimary)
            .tint(AppColor.accent)
            .privacySensitive()
    }
}
