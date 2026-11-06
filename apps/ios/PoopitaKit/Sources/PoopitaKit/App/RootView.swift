import DesignSystem
import SwiftUI

public struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let container: AppContainer
    @State private var model: TodayViewModel?
    @State private var historyModel: HistoryViewModel?
    @State private var insightsModel: InsightsViewModel?
    @State private var settingsModel: SettingsViewModel?
    @State private var remindersModel: RemindersViewModel?
    @State private var backup: BackupModel?
    @State private var undoModel: UndoModel?
    @State private var onboardingModel: OnboardingViewModel?
    @State private var appLock: AppLockModel?
    @State private var appearance: AppearanceModel
    @State private var errorMessage: String?
    @State private var selectedTab = RootTab.today
    @State private var isShowingSettings = false
    @State private var isShowingFrequency = false

    public init(container: AppContainer) {
        self.container = container
        _appearance = State(initialValue: container.appearanceModel())
    }

    public var body: some View {
        Group {
            if let model, let historyModel, let insightsModel, let settingsModel, let remindersModel, let backup, let appLock {
                AppLockGateView(appLock: appLock, asksOnAppear: true) {
                    VStack(spacing: 0) {
                        TabView(selection: $selectedTab) {
                            Tab(value: RootTab.today) {
                                NavigationStack {
                                    TodayView(viewModel: model) { isShowingSettings = true }
                                        .navigationDestination(isPresented: $isShowingSettings) {
                                            SettingsView(
                                                viewModel: settingsModel,
                                                reminders: remindersModel,
                                                backup: backup
                                            ) {
                                                isShowingSettings = false
                                            }
                                        }
                                }
                                .hidesSystemTabBar()
                            }
                            Tab(value: RootTab.history) {
                                NavigationStack {
                                    HistoryView(viewModel: historyModel)
                                }
                                .hidesSystemTabBar()
                            }
                            Tab(value: RootTab.insights) {
                                NavigationStack {
                                    InsightsView(
                                        viewModel: insightsModel, isShowingFrequency: $isShowingFrequency,
                                        doctorExport: settingsModel.pdfExport
                                    ) { dayID in
                                        historyModel.open(id: dayID)
                                        selectedTab = .history
                                    }
                                }
                                .hidesSystemTabBar()
                            }
                        }
                        .overlay(alignment: .bottom) { undoToast }
                        .animation(reduceMotion ? .default : .snappy, value: undoModel?.toast?.id)
                        if !isShowingSettings, !isShowingFrequency {
                            AppTabBarView(
                                selection: $selectedTab,
                                items: [
                                    AppTabBarItem(.today, title: Text("diary.today", bundle: .module), icon: AppIcon.today),
                                    AppTabBarItem(
                                        .history, title: Text("history.title", bundle: .module), icon: AppIcon.history
                                    ),
                                    AppTabBarItem(
                                        .insights, title: Text("tab.insights", bundle: .module), icon: AppIcon.insights
                                    ),
                                ],
                                actionTitle: Text("tab.log", bundle: .module),
                                action: presentLog
                            )
                            .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(reduceMotion ? .default : .snappy, value: isShowingSettings)
                    .animation(reduceMotion ? .default : .snappy, value: isShowingFrequency)
                    .fullScreenModal(item: editorBinding) { editor in
                        AppLockGateView(appLock: appLock, asksOnAppear: false) {
                            EntryEditorView(
                                viewModel: editor,
                                saved: editor.isEditing ? model.savedEditor : model.savedComposer,
                                delete: { model.delete(id: editor.id) },
                                deletionError: model.errorMessage
                            )
                        }
                    }
                    .sheet(isPresented: offerBinding) {
                        AppLockOfferView(appLock: appLock)
                    }
                    .fullScreenModal(isPresented: onboardingBinding) {
                        if let onboardingModel {
                            OnboardingView(viewModel: onboardingModel, reminders: remindersModel, backup: backup)
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
        .background { WindowPrivacyCoverView(isEnabled: appearance.hidesInAppSwitcher) }
        .preferredColorScheme(appearance.colorScheme)
        .task { openDiary() }
        .onChange(of: undoModel?.toast?.id) { remindersModel?.reschedule() }
        .task(id: undoModel?.toast?.id) {
            guard await (try? Task.sleep(for: .seconds(1))) != nil else { return }
            appLock?.considerOffer()
        }
        .onChange(of: remindersModel?.revision) {
            model?.load()
            historyModel?.load()
            insightsModel?.load()
        }
        .onChange(of: remindersModel?.route, initial: true) { _, route in
            guard let route else { return }
            remindersModel?.consumeRoute()
            isShowingSettings = false
            isShowingFrequency = false
            switch route {
            case .log:
                selectedTab = .today
                model?.presentLogSheet()
            case .insights:
                selectedTab = .insights
            }
        }
        .onChange(of: undoModel?.revision) {
            model?.load()
            historyModel?.load()
            insightsModel?.load()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                appLock?.didEnterBackground()
                Task { await backup?.backUpIfNeeded() }
                return
            }
            appLock?.willEnterForeground()
            if phase == .active, let remindersModel {
                Task {
                    await remindersModel.refreshPermission()
                    remindersModel.reschedule()
                }
            }
        }
    }

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { onboardingModel?.isPresented ?? false },
            set: { isPresented in
                if !isPresented {
                    onboardingModel?.finish()
                }
            }
        )
    }

    private var offerBinding: Binding<Bool> {
        Binding(
            get: { appLock?.isOffering ?? false },
            set: { isPresented in
                if !isPresented {
                    appLock?.declineOffer()
                }
            }
        )
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

    @ViewBuilder
    private var undoToast: some View {
        if let undoModel, let toast = undoModel.toast {
            ToastView(
                message: toast.message,
                actionTitle: toast.canUndo ? Text("diary.undo", bundle: .module) : nil,
                staysUntilDismissed: toast.staysUntilDismissed,
                action: undoModel.undo,
                dismiss: { undoModel.dismiss(id: toast.id) }
            )
            .id(toast.id)
            .padding(.horizontal, Spacing.lg + Spacing.xs)
            .padding(.bottom, Spacing.sm)
            .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func presentLog() {
        model?.presentLogSheet()
    }

    private func openDiary() {
        do {
            model = try container.makeTodayViewModel()
            historyModel = try container.makeHistoryViewModel()
            insightsModel = try container.makeInsightsViewModel()
            settingsModel = try container.makeSettingsViewModel()
            remindersModel = try container.remindersViewModel()
            backup = try container.backupModel()
            undoModel = try container.undoModel()
            onboardingModel = try container.makeOnboardingViewModel()
            appLock = try container.appLockModel()
            errorMessage = nil
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }
}

private enum RootTab: Hashable {
    case today, history, insights
}

private extension View {
    func hidesSystemTabBar() -> some View {
        #if os(iOS)
            toolbarVisibility(.hidden, for: .tabBar)
        #else
            self
        #endif
    }
}
