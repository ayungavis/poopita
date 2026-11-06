import DesignSystem
import SwiftUI

struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let viewModel: OnboardingViewModel
    let reminders: RemindersViewModel
    let backup: BackupModel
    @State private var isImporting = false

    var body: some View {
        let data = viewModel.state
        VStack(spacing: 0) {
            OnboardingProgressView(index: data.step.rawValue, label: data.progressLabel)
            ScrollView {
                content(data)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.xl)
                    .padding(.bottom, Spacing.lg)
                    .id(data.step)
                    .transition(.opacity)
            }
            .scrollBounceBehavior(.basedOnSize)
            actions(data.step)
        }
        .background(AppColor.background)
        .font(AppFont.body)
        .tint(AppColor.accent)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: data.step)
        .sensoryFeedback(.selection, trigger: data.step)
        .restoreBackupFlow(backup, isRequested: $isImporting) { viewModel.finish() }
    }

    @ViewBuilder
    private func content(_ data: OnboardingViewData) -> some View {
        switch data.step {
        case .welcome:
            OnboardingWelcomeView()
        case .marks:
            OnboardingMarksView(days: data.sampleWeek)
        case .reminder:
            OnboardingReminderView(reminders: reminders)
        }
    }

    private func actions(_ step: OnboardingViewData.Step) -> some View {
        let isReminder = step == .reminder
        return VStack(spacing: Spacing.xs) {
            PrimaryButtonView(
                Text(isReminder ? "onboarding.turnOn" : "onboarding.continue", bundle: .module),
                action: isReminder ? turnOnReminder : viewModel.next
            )
            Button(action: viewModel.finish) {
                Text(isReminder ? "onboarding.notNow" : "onboarding.skip", bundle: .module)
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(AppColor.accent)
                    .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if step == .welcome {
                Button { isImporting = true } label: {
                    Text("onboarding.restore", bundle: .module)
                        .font(AppFont.body.weight(.semibold))
                        .foregroundStyle(AppColor.accent)
                        .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(backup.isWorking)
            }
            if let error = backup.errorMessage {
                Text(verbatim: error)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.destructive)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
    }

    private func turnOnReminder() {
        Task {
            reminders.setEnabled(true)
            await reminders.requestPermission()
            viewModel.finish()
        }
    }
}
