import DesignSystem
import SwiftUI

struct SettingsContentView: View {
    let viewModel: SettingsViewModel
    let data: SettingsViewData
    @State private var confirmDeleteAll = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if let error = viewModel.errorMessage {
                    Text(verbatim: error).foregroundStyle(AppColor.destructive)
                }
                reminderSection
                SettingsAppearanceView(
                    data: data.appearance, selectTheme: viewModel.selectTheme, selectLanguage: viewModel.selectLanguage
                )
                privacySection
                backupSection
                aboutSection
                dataManagementSection
            }
            .padding(Spacing.lg)
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
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("settings.reminders.title", bundle: .module)
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Toggle(isOn: Binding(
                get: { data.isReminderEnabled },
                set: { enabled in Task { await viewModel.toggleReminder(enabled) } }
            )) {
                Text("settings.reminders.dailyCheckIn", bundle: .module)
                    .font(AppFont.body)
            }
            .tint(AppColor.accent)

            if data.isReminderEnabled {
                DatePicker(
                    selection: Binding(
                        get: { data.reminderDate },
                        set: { date in Task { await viewModel.setReminderDate(date) } }
                    ),
                    displayedComponents: [.hourAndMinute]
                ) {
                    Text("settings.reminders.time", bundle: .module)
                }
                .font(AppFont.body)
            }

            Text("settings.reminders.discreetHint", bundle: .module)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("settings.privacy.title", bundle: .module)
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Toggle(isOn: Binding(
                get: { data.isAppLockEnabled },
                set: { enabled in Task { await viewModel.toggleAppLock(enabled) } }
            )) {
                Text("settings.privacy.appLock", bundle: .module)
                    .font(AppFont.body)
            }
            .tint(AppColor.accent)
            .disabled(!data.isBiometricsAvailable)

            Text("settings.privacy.appSwitcherHint", bundle: .module)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }

    private var backupSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("settings.backup.title", bundle: .module)
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("settings.backup.status", bundle: .module)
                .font(AppFont.body.weight(.semibold))

            DisclosureGroup {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("settings.backup.explainer1", bundle: .module)
                    Text("settings.backup.explainer2", bundle: .module)
                }
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.top, Spacing.xs)
            } label: {
                Text("settings.backup.howItWorks", bundle: .module)
                    .font(AppFont.body)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("settings.about.title", bundle: .module)
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("settings.about.philosophy", bundle: .module)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("settings.data.title", bundle: .module)
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Button(role: .destructive) {
                confirmDeleteAll = true
            } label: {
                Text("settings.data.deleteAll", bundle: .module)
                    .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
            }
            .buttonStyle(.bordered)
            .tint(AppColor.destructive)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }
}
