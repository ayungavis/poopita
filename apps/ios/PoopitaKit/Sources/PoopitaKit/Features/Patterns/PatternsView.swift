import DesignSystem
import SwiftUI

struct PatternsView: View {
    @State private var viewModel: PatternsViewModel

    init(viewModel: PatternsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case let .failed(error):
                VStack(spacing: Spacing.lg) {
                    Text(verbatim: error.userMessage)
                    PrimaryButtonView(Text("diary.retry", bundle: .module), action: viewModel.load)
                }
                .padding(Spacing.lg)
            case let .loaded(data):
                PatternsContentView(viewModel: viewModel, data: data)
            }
        }
        .background(AppColor.background)
        .navigationTitle(Text("patterns.title", bundle: .module))
        .font(AppFont.body)
        .foregroundStyle(AppColor.textPrimary)
        .tint(AppColor.accent)
        .privacySensitive()
        .task { viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            viewModel.load()
        }
    }
}
