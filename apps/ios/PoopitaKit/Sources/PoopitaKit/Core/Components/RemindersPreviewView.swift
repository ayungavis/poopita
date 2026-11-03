import DesignSystem
import SwiftUI

struct RemindersPreviewView: View {
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image("appIcon", bundle: .module)
                .resizable()
                .frame(width: Spacing.touchTarget, height: Spacing.touchTarget)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.sm + Spacing.xs / 2))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                HStack {
                    Text(verbatim: "POOPITA")
                    Spacer()
                    Text("reminders.now", bundle: .module)
                }
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
                Text("reminders.notificationTitle", bundle: .module)
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text("reminders.notificationBody", bundle: .module)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Spacing.md)
        .accessibilityElement(children: .combine)
    }
}
