import DesignSystem
import SwiftUI

struct EntryFieldsView: View {
    let viewModel: EntryEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            section(.type, title: Text("entry.typeLabel", bundle: .module)) {
                EntryTileGridView(
                    choices: EntryChoiceViewData.types, selected: viewModel.draft.stoolType.map(String.init),
                    columns: 4, select: viewModel.selectType
                )
                selectionLine(EntryChoiceViewData.types, viewModel.draft.stoolType.map(String.init))
            }
            section(.amount, title: Text("entry.amountLabel", bundle: .module)) {
                EntryTileGridView(
                    choices: EntryChoiceViewData.amounts, selected: viewModel.draft.amount, columns: 5,
                    select: viewModel.setAmount
                )
                selectionLine(EntryChoiceViewData.amounts, viewModel.draft.amount)
            }
            section(.effort, title: Text("entry.effortLabel", bundle: .module)) {
                EntryTileGridView(
                    choices: EntryChoiceViewData.efforts, selected: viewModel.draft.effort, columns: 3,
                    select: viewModel.setEffort
                )
            }
            section(.blood, title: Text("entry.bloodLabel", bundle: .module)) {
                EntryTileGridView(
                    choices: EntryChoiceViewData.bloods, selected: viewModel.draft.blood, columns: 2,
                    select: viewModel.setBlood
                )
            }
            EntryFieldSectionView(title: Text("entry.colorLabel", bundle: .module), isOptional: true, isMissing: false) {
                EntrySwatchRowView(
                    choices: EntryChoiceViewData.colors,
                    selected: viewModel.draft.color,
                    select: viewModel.setColor
                )
                selectionLine(EntryChoiceViewData.colors, viewModel.draft.color)
            }
            .id(EntryFieldStep.color)
            EntryFieldSectionView(title: Text("entry.durationLabel", bundle: .module), isOptional: true, isMissing: false) {
                EntryTileGridView(
                    choices: EntryChoiceViewData.durations, selected: viewModel.draft.duration, columns: 4,
                    select: viewModel.setDuration
                )
            }
            .id(EntryFieldStep.duration)
            EntryFieldSectionView(title: Text("entry.noteLabel", bundle: .module), isOptional: true, isMissing: false) {
                TextField(
                    "", text: Binding(get: { viewModel.draft.note }, set: viewModel.setNote),
                    prompt: Text("entry.notePrompt", bundle: .module), axis: .vertical
                )
                .lineLimit(3 ... 6)
                .padding(Spacing.md)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
                .accessibilityLabel(Text("entry.noteLabel", bundle: .module))
                EntrySuggestionChipsView(
                    suggestions: EntryChoiceViewData.suggestions, isAdded: viewModel.hasSuggestion,
                    toggle: viewModel.toggleSuggestion
                )
            }
        }
    }

    private func section(
        _ field: EntryRequiredField, title: Text, @ViewBuilder content: () -> some View
    ) -> some View {
        EntryFieldSectionView(
            title: title,
            isOptional: false,
            isMissing: viewModel.missingFields.contains(field),
            content: content
        )
        .id(EntryFieldStep(field))
    }

    @ViewBuilder
    private func selectionLine(_ choices: [EntryChoiceViewData], _ selected: String?) -> some View {
        if let choice = choices.first(where: { $0.id == selected }) {
            Text(verbatim: [choice.title, choice.detail].filter { !$0.isEmpty }.joined(separator: " · "))
                .font(AppFont.body.weight(.medium))
                .foregroundStyle(AppColor.textPrimary)
        }
    }
}
