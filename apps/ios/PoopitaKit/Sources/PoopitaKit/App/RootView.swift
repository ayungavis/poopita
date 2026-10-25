import DesignSystem
import SwiftUI

public struct RootView: View {
    private let container: AppContainer
    @State private var model: TodayViewModel?
    @State private var errorMessage: String?

    public init(container: AppContainer) {
        self.container = container
    }

    public var body: some View {
        NavigationStack { content }
            .font(AppFont.body)
            .background(AppColor.background)
            .background { WindowPrivacyCoverView() }
            .task { openDiary() }
    }

    @ViewBuilder
    private var content: some View {
        if let model {
            TodayView(viewModel: model)
        } else {
            VStack(spacing: Spacing.lg) {
                if let errorMessage {
                    Text(verbatim: errorMessage)
                    PrimaryButtonView(Text("diary.retry", bundle: .module), action: openDiary)
                } else {
                    ProgressView()
                }
            }
            .padding(Spacing.lg)
        }
    }

    private func openDiary() {
        do {
            model = try container.makeTodayViewModel()
            errorMessage = nil
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }
}
