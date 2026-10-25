import DesignSystem
import SwiftUI

struct HistoryView: View {
    @State private var viewModel: HistoryViewModel

    init(viewModel: HistoryViewModel) {
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
                HistoryContentView(viewModel: viewModel, data: data)
            }
        }
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
