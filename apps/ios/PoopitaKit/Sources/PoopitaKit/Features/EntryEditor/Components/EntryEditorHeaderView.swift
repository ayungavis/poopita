import DesignSystem
import SwiftUI

struct EntryEditorHeaderView: View {
    let viewModel: EntryEditorViewModel
    let close: () -> Void
    @State private var picking: EntryWhenPickerView.Field?

    var body: some View {
        let labels = viewModel.whenLabels
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(viewModel.isEditing ? "entry.editTitle" : "entry.newTitle", bundle: .module)
                    .font(AppFont.title).foregroundStyle(AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
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
            HStack(spacing: Spacing.sm) {
                field(.date, icon: AppIcon.today, value: labels.date)
                field(.time, icon: AppIcon.clock, value: labels.time)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .sheet(item: $picking) { EntryWhenPickerView(viewModel: viewModel, field: $0) }
    }

    private func field(_ field: EntryWhenPickerView.Field, icon: Image, value: String) -> some View {
        Button { picking = field } label: {
            VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                HStack(spacing: Spacing.iconGap) {
                    icon.resizable().scaledToFit().frame(width: Spacing.icon, height: Spacing.icon)
                    Text(field.title, bundle: .module)
                }
                .font(AppFont.caption.weight(.medium))
                .foregroundStyle(AppColor.textSecondary)
                HStack(spacing: Spacing.xs) {
                    Text(verbatim: value)
                        .font(AppFont.body.weight(.semibold))
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(AppFont.caption.weight(.semibold))
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
            .overlay {
                RoundedRectangle(cornerRadius: Spacing.md).strokeBorder(AppColor.hairline, lineWidth: Spacing.borderWidth)
            }
            .contentShape(RoundedRectangle(cornerRadius: Spacing.md))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(field.title, bundle: .module))
        .accessibilityValue(Text(verbatim: value))
        .accessibilityAddTraits(.isButton)
    }
}
