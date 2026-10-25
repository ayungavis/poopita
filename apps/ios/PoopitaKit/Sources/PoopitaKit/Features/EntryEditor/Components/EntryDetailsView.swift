import DesignSystem
import SwiftUI

struct EntryDetailsView: View {
    let viewModel: EntryEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("entry.amount", bundle: .module).font(AppFont.body.weight(.semibold))
                    Spacer()
                    Button { viewModel.setAmount(nil) } label: { Text("entry.clearAmount", bundle: .module) }
                        .frame(minHeight: Spacing.touchTarget)
                }
                EntryChoiceGridView(
                    choices: EntryChoiceViewData.amounts, selected: viewModel.draft.amount, select: viewModel.setAmount
                )
            }
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("entry.effort", bundle: .module).font(AppFont.body.weight(.semibold))
                    Spacer()
                    Button { viewModel.setEffort(nil) } label: { Text("entry.clearEffort", bundle: .module) }
                        .frame(minHeight: Spacing.touchTarget)
                }
                EntryChoiceGridView(
                    choices: EntryChoiceViewData.efforts, selected: viewModel.draft.effort, select: viewModel.setEffort
                )
            }
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("entry.note", bundle: .module).font(AppFont.body.weight(.semibold))
                TextField(
                    "", text: Binding(get: { viewModel.draft.note }, set: viewModel.setNote),
                    prompt: Text("entry.notePrompt", bundle: .module), axis: .vertical
                )
                .lineLimit(2 ... 6)
                .padding(Spacing.md)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
                .accessibilityLabel(Text("entry.note", bundle: .module))
                Text("entry.noteLimit", bundle: .module)
                    .font(AppFont.caption).foregroundStyle(AppColor.textSecondary)
            }
        }
    }
}
