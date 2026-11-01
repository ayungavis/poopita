import DesignSystem
import SwiftUI

struct SettingsContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let viewModel: SettingsViewModel
    let data: SettingsViewData
    @State private var confirmDeleteAll = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl - Spacing.xs) {
                if let error = viewModel.errorMessage {
                    Text(verbatim: error)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.destructive)
                }
                reminderSection
                SettingsAppearanceView(
                    data: data.appearance, selectTheme: viewModel.selectTheme, selectLanguage: viewModel.selectLanguage,
                    confirmLanguageChange: viewModel.confirmLanguageChange,
                    cancelLanguageChange: viewModel.cancelLanguageChange
                )
                privacySection
                dataSection
                footer
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxl)
        }
        .confirmationDialog(Text("settings.deleteHistoryQuestion", bundle: .module), isPresented: $confirmDeleteAll) {
            Button(role: .destructive) {
                try? viewModel.deleteAllHistory()
            } label: {
                Text("settings.deleteAll", bundle: .module)
            }
            Button(role: .cancel) {} label: {
                Text("entry.cancel", bundle: .module)
            }
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            if let error {
                AccessibilityNotification.Announcement(error).post()
            }
        }
    }

    private var reminderSection: some View {
        SettingsSectionView("settings.reminders.title", footnote: "settings.reminders.discreetHint") {
            Toggle(isOn: Binding(
                get: { data.isReminderEnabled },
                set: { enabled in Task { await viewModel.toggleReminder(enabled) } }
            )) {
                Text("settings.reminders.dailyCheckIn", bundle: .module)
            }
            .tint(AppColor.ink)
            .settingsRow()
            if data.isReminderEnabled {
                SettingsDividerView()
                DatePicker(
                    selection: Binding(
                        get: { data.reminderDate },
                        set: { date in Task { await viewModel.setReminderDate(date) } }
                    ),
                    displayedComponents: [.hourAndMinute]
                ) {
                    Text("settings.reminders.time", bundle: .module)
                }
                .settingsRow()
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: data.isReminderEnabled)
    }

    private var privacySection: some View {
        SettingsSectionView("settings.privacy.title", footnote: "settings.privacy.appSwitcherHint") {
            Toggle(isOn: Binding(
                get: { data.isAppLockEnabled },
                set: { enabled in Task { await viewModel.toggleAppLock(enabled) } }
            )) {
                Text("settings.privacy.appLock", bundle: .module)
            }
            .tint(AppColor.ink)
            .disabled(!data.isBiometricsAvailable)
            .settingsRow()
        }
    }

    private var dataSection: some View {
        SettingsSectionView("settings.data.title") {
            HStack(spacing: Spacing.sm) {
                Text("settings.backup.title", bundle: .module)
                Spacer(minLength: Spacing.md)
                Text("settings.backup.notSetUp", bundle: .module)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .settingsRow()
            .accessibilityElement(children: .combine)
            SettingsDividerView()
            DisclosureGroup {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("settings.backup.explainer1", bundle: .module)
                    Text("settings.backup.explainer2", bundle: .module)
                }
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.bottom, Spacing.md)
            } label: {
                Text("settings.backup.howItWorks", bundle: .module)
                    .settingsRow()
            }
            .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var footer: some View {
        VStack(spacing: Spacing.md) {
            Text(verbatim: viewModel.footer)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            Button { confirmDeleteAll = true } label: {
                Text("settings.data.deleteAll", bundle: .module)
                    .font(AppFont.body.weight(.medium))
                    .foregroundStyle(AppColor.destructive)
                    .frame(minHeight: Spacing.touchTarget)
                    .padding(.horizontal, Spacing.lg)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }
}
