import DesignSystem
import SwiftUI

struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: TodayViewModel
    @State private var isHeaderHidden = false
    private let openSettings: () -> Void

    init(viewModel: TodayViewModel, openSettings: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.openSettings = openSettings
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
                TodayContentView(viewModel: viewModel, data: data, isHeaderHidden: $isHeaderHidden)
            }
        }
        .background(AppColor.background)
        .safeAreaInset(edge: .top, spacing: 0) {
            TodayTopBarView(data: loadedData, isCompact: isHeaderHidden, openSettings: openSettings)
        }
        .privacySensitive()
        #if os(iOS)
            .toolbarVisibility(.hidden, for: .navigationBar)
        #endif
            .font(AppFont.body)
            .foregroundStyle(AppColor.textPrimary)
            .tint(AppColor.accent)
            .task {
                viewModel.load()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                viewModel.load()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    viewModel.load()
                }
            }
    }

    private var loadedData: TodayViewData? {
        if case let .loaded(data) = viewModel.state {
            data
        } else {
            nil
        }
    }
}
