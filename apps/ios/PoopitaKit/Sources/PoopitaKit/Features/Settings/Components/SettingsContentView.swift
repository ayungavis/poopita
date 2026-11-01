import DesignSystem
import SwiftUI

struct SettingsContentView: View {
    let viewModel: SettingsViewModel
    let reminders: RemindersViewModel
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
                SettingsDataView(csvExport: viewModel.csvExport, pdfExport: viewModel.pdfExport)
                helpSection
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
        CardSectionView("settings.reminders.title") {
            NavigationLink {
                RemindersView(viewModel: reminders)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Text("settings.reminders.dailyCheckIn", bundle: .module)
                    Spacer(minLength: Spacing.md)
                    Text(verbatim: reminders.state.summary)
                        .foregroundStyle(AppColor.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(AppFont.caption.weight(.semibold))
                        .foregroundStyle(AppColor.textSecondary)
                        .accessibilityHidden(true)
                }
                .cardRow()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var privacySection: some View {
        CardSectionView("settings.privacy.title") {
            Toggle(isOn: Binding(
                get: { data.isAppLockEnabled },
                set: { enabled in Task { await viewModel.toggleAppLock(enabled) } }
            )) {
                Text("settings.privacy.appLock", bundle: .module)
            }
            .tint(AppColor.ink)
            .disabled(!data.isBiometricsAvailable)
            .cardRow()
            CardDividerView()
            Toggle(isOn: Binding(get: { data.appearance.hidesInAppSwitcher }, set: viewModel.setHidesInAppSwitcher)) {
                Text("settings.privacy.hideInSwitcher", bundle: .module)
            }
            .tint(AppColor.ink)
            .cardRow()
        }
    }

    private var helpSection: some View {
        CardSectionView("settings.help.title") {
            NavigationLink {
                SettingsBristolGuideView(guide: SettingsViewModel.guide)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Text("settings.help.bristol", bundle: .module)
                    Spacer(minLength: Spacing.md)
                    Image(systemName: "chevron.right")
                        .font(AppFont.caption.weight(.semibold))
                        .foregroundStyle(AppColor.textSecondary)
                        .accessibilityHidden(true)
                }
                .cardRow()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
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
