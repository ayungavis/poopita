import DesignSystem
import SwiftUI

struct EntryFieldsView: View {
    let viewModel: EntryEditorViewModel
    @State private var detailsExpanded = false
    @AccessibilityFocusState private var errorFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            DatePicker(
                selection: Binding(get: { viewModel.draft.occurrenceDate }, set: viewModel.setDate),
                in: ...viewModel.maximumDate, displayedComponents: [.date]
            ) { Text("entry.date", bundle: .module) }
                .environment(\.timeZone, viewModel.displayTimeZone)
            DatePicker(
                selection: Binding(get: { viewModel.draft.occurrenceDate }, set: viewModel.setDate),
                in: ...viewModel.maximumDate, displayedComponents: [.hourAndMinute]
            ) { Text("entry.time", bundle: .module) }
                .environment(\.timeZone, viewModel.displayTimeZone)
            Text(verbatim: viewModel.draft.timeZoneIdentifier)
                .font(AppFont.caption).foregroundStyle(AppColor.textSecondary)
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("entry.stoolType", bundle: .module).font(AppFont.body.weight(.semibold))
                EntryChoiceGridView(
                    choices: EntryChoiceViewData.types,
                    selected: viewModel.draft.stoolType.map(String.init) ?? "skip", select: viewModel.selectType
                )
            }
            if viewModel.isEditing {
                EntryDetailsView(viewModel: viewModel)
            } else {
                DisclosureGroup(isExpanded: $detailsExpanded) {
                    EntryDetailsView(viewModel: viewModel).padding(.top, Spacing.md)
                } label: {
                    Text("entry.moreDetails", bundle: .module)
                        .font(AppFont.body).frame(minHeight: Spacing.touchTarget)
                }
            }
            if let error = viewModel.errorMessage {
                Text(verbatim: error).foregroundStyle(AppColor.destructive)
                    .accessibilityFocused($errorFocused)
            }
        }
        .font(AppFont.body)
        .onChange(of: viewModel.errorMessage) { _, value in errorFocused = value != nil }
    }
}
