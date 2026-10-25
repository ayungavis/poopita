import DesignSystem
import SwiftUI

public struct RootView: View {
    private let container: AppContainer
    @State private var model: TodayViewModel?
    @State private var historyModel: HistoryViewModel?
    @State private var patternsModel: PatternsViewModel?
    @State private var errorMessage: String?

    public init(container: AppContainer) {
        self.container = container
    }

    public var body: some View {
        Group {
            if let model, let historyModel, let patternsModel {
                TabView {
                    NavigationStack {
                        TodayView(viewModel: model)
                    }
                    .tabItem {
                        Label {
                            Text("diary.today", bundle: .module)
                        } icon: {
                            Image(systemName: "house")
                        }
                    }
                    NavigationStack {
                        HistoryView(viewModel: historyModel)
                    }
                    .tabItem {
                        Label {
                            Text("history.title", bundle: .module)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                    }
                    NavigationStack {
                        PatternsView(viewModel: patternsModel)
                    }
                    .tabItem {
                        Label {
                            Text("patterns.title", bundle: .module)
                        } icon: {
                            Image(systemName: "chart.bar")
                        }
                    }
                }
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
        .font(AppFont.body)
        .background(AppColor.background)
        .background { WindowPrivacyCoverView() }
        .task { openDiary() }
    }

    private func openDiary() {
        do {
            model = try container.makeTodayViewModel()
            historyModel = try container.makeHistoryViewModel()
            patternsModel = try container.makePatternsViewModel()
            errorMessage = nil
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }
}
