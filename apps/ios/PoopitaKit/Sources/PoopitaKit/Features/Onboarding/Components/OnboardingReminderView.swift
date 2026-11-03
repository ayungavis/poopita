import DesignSystem
import SwiftUI

struct OnboardingReminderView: View {
    let reminders: RemindersViewModel

    var body: some View {
        let data = reminders.state
        VStack(alignment: .leading, spacing: Spacing.xl) {
            OnboardingHeroView(title: "onboarding.reminder.title", message: "onboarding.reminder.message") {
                OnboardingSymbolBadgeView(systemName: "bell")
            }
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(verbatim: data.previewLabel)
                    .font(AppFont.caption.weight(.medium))
                    .foregroundStyle(AppColor.textSecondary)
                RemindersPreviewView()
                    .padding(.horizontal, Spacing.lg)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
            }
            CardSectionView(nil, footnote: "onboarding.reminder.footnote") {
                DatePicker(
                    selection: Binding(get: { data.time }, set: { reminders.setTime($0) }),
                    displayedComponents: .hourAndMinute
                ) {
                    Text("reminders.time", bundle: .module)
                }
                .cardRow()
            }
        }
    }
}
