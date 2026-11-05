import DesignSystem
import SwiftUI

struct RemindersView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let viewModel: RemindersViewModel

    var body: some View {
        let data = viewModel.state
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl - Spacing.xs) {
                if let error = viewModel.errorMessage {
                    Text(verbatim: error)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.destructive)
                }
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(verbatim: data.previewLabel)
                        .font(AppFont.caption.weight(.medium))
                        .foregroundStyle(AppColor.textSecondary)
                    RemindersPreviewView()
                        .padding(.horizontal, Spacing.lg)
                        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
                }
                dailySection(data)
                optionsSection(data)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxl)
        }
        .safeAreaInset(edge: .bottom) {
            if data.permission != .allowed {
                RemindersPermissionBarView(isDenied: data.permission == .denied) {
                    Task { await viewModel.requestPermission() }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: data.permission)
        .background(AppColor.background)
        .navigationTitle(Text("reminders.title", bundle: .module))
        .font(AppFont.body)
        .tint(AppColor.accent)
        .task { await viewModel.refreshPermission() }
    }

    private func dailySection(_ data: RemindersViewData) -> some View {
        CardSectionView("reminders.dailySection") {
            Toggle(isOn: Binding(get: { data.isEnabled }, set: { viewModel.setEnabled($0) })) {
                Text("reminders.remindMe", bundle: .module)
            }
            .tint(AppColor.switchOn)
            .cardRow()
            CardDividerView()
            DatePicker(
                selection: Binding(get: { data.time }, set: { viewModel.setTime($0) }), displayedComponents: .hourAndMinute
            ) {
                Text("reminders.time", bundle: .module)
            }
            .cardRow()
            CardDividerView()
            NavigationLink {
                RemindersDaysView(days: data.days, toggle: viewModel.toggleDay)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Text("reminders.days", bundle: .module)
                    Spacer(minLength: Spacing.md)
                    Text(verbatim: data.daysLabel)
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

    private func optionsSection(_ data: RemindersViewData) -> some View {
        CardSectionView("reminders.options", footnote: "reminders.footnote") {
            Toggle(isOn: Binding(get: { data.skipsLoggedDays }, set: { viewModel.setSkipsLoggedDays($0) })) {
                Text("reminders.skip", bundle: .module)
            }
            .tint(AppColor.switchOn)
            .cardRow()
            CardDividerView()
            Toggle(isOn: Binding(get: { data.sendsWeeklySummary }, set: { viewModel.setSendsWeeklySummary($0) })) {
                Text("reminders.weeklySummary", bundle: .module)
            }
            .tint(AppColor.switchOn)
            .cardRow()
            CardDividerView()
            Toggle(isOn: Binding(get: { data.alertsAfterGap }, set: { viewModel.setAlertsAfterGap($0) })) {
                Text("reminders.gap", bundle: .module)
            }
            .tint(AppColor.switchOn)
            .cardRow()
        }
    }
}
