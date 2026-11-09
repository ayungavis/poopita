import DesignSystem
import SwiftUI

struct EntryFieldsView: View {
    let viewModel: EntryEditorViewModel
    @State private var showsGuide = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            if let summary = viewModel.repeatSummary {
                EntryRepeatButtonView(summary: summary, action: viewModel.repeatLastTime)
            }
            section(.type, title: Text("entry.typeLabel", bundle: .module), accessory: guideLink) {
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
                    "", text: Binding(get: { viewModel.draft.note }, set: { viewModel.setNote($0) }),
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
        _ field: EntryRequiredField, title: Text, accessory: some View = EmptyView(),
        @ViewBuilder content: () -> some View
    ) -> some View {
        EntryFieldSectionView(
            title: title,
            isOptional: false,
            isMissing: viewModel.missingFields.contains(field),
            accessory: { accessory },
            content: content
        )
        .id(EntryFieldStep(field))
    }

    private var guideLink: some View {
        Button { showsGuide = true } label: {
            Text("entry.bristolGuide", bundle: .module)
                .font(AppFont.caption.weight(.medium))
                .foregroundStyle(AppColor.accent)
                .frame(minHeight: Spacing.touchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, -Spacing.md)
        .sheet(isPresented: $showsGuide) {
            NavigationStack {
                BristolGuideView(guide: .standard)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button { showsGuide = false } label: {
                                Text("entry.done", bundle: .module)
                            }
                        }
                    }
            }
            .presentationDragIndicator(.visible)
        }
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
