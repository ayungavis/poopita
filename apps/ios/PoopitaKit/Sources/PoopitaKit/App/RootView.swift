import DesignSystem
import SwiftUI

public struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    private let container: AppContainer
    @State private var model: TodayViewModel?
    @State private var historyModel: HistoryViewModel?
    @State private var patternsModel: PatternsViewModel?
    @State private var settingsModel: SettingsViewModel?
    @State private var isUnlocked = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0

    public init(container: AppContainer) {
        self.container = container
    }

    public var body: some View {
        Group {
            if let model, let historyModel, let patternsModel, let settingsModel {
                if settingsModel.state.isAppLockEnabled, !isUnlocked {
                    lockScreen(settingsModel)
                } else {
                    TabView(selection: $selectedTab) {
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
                        .tag(0)
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
                        .tag(1)
                        Button(action: presentLog) {
                            Label {
                                Text("tab.log", bundle: .module)
                            } icon: {
                                Image(systemName: "plus")
                            }
                        }
                        .tabItem {
                            Label {
                                Text("tab.log", bundle: .module)
                            } icon: {
                                Image(systemName: "plus")
                            }
                        }
                        .tag(4)
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
                        .tag(2)
                        NavigationStack {
                            SettingsView(viewModel: settingsModel)
                        }
                        .tabItem {
                            Label {
                                Text("settings.title", bundle: .module)
                            } icon: {
                                Image(systemName: "gearshape")
                            }
                        }
                        .tag(3)
                    }
                    .onChange(of: selectedTab) { oldTab, newTab in
                        if newTab == 4 {
                            selectedTab = oldTab
                            presentLog()
                        }
                    }
                    .sheet(item: editorBinding) { editor in
                        EntryEditorView(
                            viewModel: editor,
                            saved: editor.isEditing ? model.savedEditor : model.savedComposer,
                            delete: { model.delete(id: editor.id) },
                            deletionError: model.errorMessage
                        )
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                isUnlocked = false
            }
        }
    }

    private var editorBinding: Binding<EntryEditorViewModel?> {
        Binding(
            get: { model?.editor },
            set: {
                if $0 == nil {
                    model?.dismissEditor()
                }
            }
        )
    }

    private func presentLog() {
        model?.presentLogSheet()
    }

    private func lockScreen(_ settings: SettingsViewModel) -> some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "lock.shield")
                .font(AppFont.largeTitle)
                .foregroundStyle(AppColor.accent)
            Text("settings.appLock.lockedTitle", bundle: .module)
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
            PrimaryButtonView(Text("settings.appLock.unlockButton", bundle: .module)) {
                Task {
                    if await settings.authenticateToUnlock() {
                        isUnlocked = true
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
        .task {
            if await settings.authenticateToUnlock() {
                isUnlocked = true
            }
        }
    }

    private func openDiary() {
        do {
            model = try container.makeTodayViewModel()
            historyModel = try container.makeHistoryViewModel()
            patternsModel = try container.makePatternsViewModel()
            settingsModel = try container.makeSettingsViewModel()
            errorMessage = nil
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }
}
