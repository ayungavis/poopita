import DesignSystem
import SwiftUI

struct EntryEditorHeaderView: View {
    let viewModel: EntryEditorViewModel
    let close: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(viewModel.isEditing ? "entry.editTitle" : "entry.newTitle", bundle: .module)
                    .font(AppFont.title).foregroundStyle(AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: Spacing.md) {
                    picker(icon: AppIcon.today, components: .date, label: Text("entry.date", bundle: .module))
                    picker(icon: AppIcon.clock, components: .hourAndMinute, label: Text("entry.time", bundle: .module))
                }
            }
            Spacer()
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: Spacing.touchTarget, height: Spacing.touchTarget)
                    .background(AppColor.track, in: Circle())
            }
            .accessibilityLabel(Text("entry.close", bundle: .module))
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    private func picker(icon: Image, components: DatePickerComponents, label: Text) -> some View {
        HStack(spacing: Spacing.xs) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: Spacing.icon, height: Spacing.icon)
                .foregroundStyle(AppColor.textSecondary)
                .accessibilityHidden(true)
            DatePicker(
                selection: Binding(get: { viewModel.draft.occurrenceDate }, set: viewModel.setDate),
                in: ...viewModel.maximumDate, displayedComponents: components
            ) { label }
                .labelsHidden()
                .datePickerStyle(.compact)
                .environment(\.timeZone, viewModel.displayTimeZone)
        }
    }
}
