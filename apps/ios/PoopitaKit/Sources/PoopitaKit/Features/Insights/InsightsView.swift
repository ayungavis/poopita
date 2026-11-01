import DesignSystem
import SwiftUI

struct InsightsView: View {
    @State private var viewModel: InsightsViewModel
    @Binding private var isShowingFrequency: Bool
    private let doctorExport: SettingsExportViewData
    private let openDay: (String) -> Void

    init(
        viewModel: InsightsViewModel, isShowingFrequency: Binding<Bool>, doctorExport: SettingsExportViewData,
        openDay: @escaping (String) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        _isShowingFrequency = isShowingFrequency
        self.doctorExport = doctorExport
        self.openDay = openDay
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
                InsightsContentView(
                    viewModel: viewModel, data: data, doctorExport: doctorExport,
                    showFrequency: { isShowingFrequency = true }, openDay: openDay
                )
            }
        }
        .background(AppColor.background)
        .navigationTitle(Text("tab.insights", bundle: .module))
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.background, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        #endif
            .navigationDestination(isPresented: $isShowingFrequency) {
                InsightsFrequencyView(viewModel: viewModel)
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
