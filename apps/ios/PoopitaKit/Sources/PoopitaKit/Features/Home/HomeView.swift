import DesignSystem
import SwiftUI

public struct HomeView: View {
    @State private var viewModel: HomeViewModel

    public init(viewModel: HomeViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("home.title", bundle: .module)
                .font(AppFont.largeTitle)
                .foregroundStyle(AppColor.textPrimary)

            statusContent
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)

            PrimaryButtonView(Text("home.retry", bundle: .module)) {
                viewModel.load()
            }
            .disabled(viewModel.state == .loading)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
        .onAppear { viewModel.load() }
    }

    @ViewBuilder
    private var statusContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case let .loaded(data):
            Text(data.statusMessage)
        case let .failed(error):
            Text(error.userMessage)
                .foregroundStyle(AppColor.destructive)
        }
    }
}
