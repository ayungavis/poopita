import DesignSystem
import SwiftUI

struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: TodayViewModel
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
                TodayContentView(viewModel: viewModel, data: data)
            }
        }
        .background(AppColor.background)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: openSettings) {
                    AppIcon.settings
                        .resizable()
                        .scaledToFit()
                        .frame(width: Spacing.icon, height: Spacing.icon)
                        .foregroundStyle(AppColor.textPrimary)
                }
                .accessibilityLabel(Text("settings.title", bundle: .module))
            }
        }
        .font(AppFont.body)
        .foregroundStyle(AppColor.textPrimary)
        .tint(AppColor.accent)
        .privacySensitive()
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
}
