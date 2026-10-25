import DesignSystem
import SwiftUI

struct HistoryContentView: View {
    let viewModel: HistoryViewModel
    let data: HistoryViewData
    @AccessibilityFocusState private var focusedEntry: UUID?
    @State private var editedID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let feedback = viewModel.feedback {
                    Text(verbatim: feedback)
                        .accessibilityAddTraits(.updatesFrequently)
                }
                if let error = viewModel.errorMessage {
                    Text(verbatim: error).foregroundStyle(AppColor.destructive)
                }
                calendarCard
                selectedDay
                legend
            }
            .padding(Spacing.lg)
        }
        .background(AppColor.background)
        .navigationTitle(Text("history.title", bundle: .module))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: viewModel.showToday) { Text("history.today", bundle: .module) }
            }
        }
        .sheet(item: editorBinding, onDismiss: dismissed) { editor in
            EntryEditorView(
                viewModel: editor, saved: viewModel.savedEditor,
                delete: { viewModel.delete(id: editor.id) }, deletionError: viewModel.errorMessage
            )
        }
    }

    private var calendarCard: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Button { viewModel.moveMonth(-1) } label: {
                    Image(systemName: "chevron.left").frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
                }
                .accessibilityLabel(Text("history.previousMonth", bundle: .module))
                Spacer()
                Text(verbatim: data.monthLabel).font(AppFont.title)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button { viewModel.moveMonth(1) } label: {
                    Image(systemName: "chevron.right").frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
                }
                .disabled(!data.canMoveNext)
                .accessibilityLabel(Text("history.nextMonth", bundle: .module))
            }
            HistoryCalendarView(data: data.calendar, selectedID: data.selected.dayID,
                                todayID: data.todayID, select: viewModel.select(id:))
        }
        .padding(Spacing.lg)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }

    private var selectedDay: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(verbatim: data.selected.dateLabel).font(AppFont.title).accessibilityAddTraits(.isHeader)
                Spacer()
                if data.selected.status == .logged || data.selected.status == .completed || data.selected.status == .partial {
                    marker(data.selected.status)
                        .frame(width: Spacing.md, height: Spacing.md)
                        .accessibilityHidden(true)
                }
            }
            Text(verbatim: selectedStatus)
                .font(AppFont.body.weight(.semibold))
            if let checkInStatus = data.selected.checkInStatus, data.selected.entries.isEmpty {
                Text(verbatim: checkInStatus).foregroundStyle(AppColor.textSecondary)
            }
            if data.selected.entries.isEmpty {
                Text("history.emptyDay", bundle: .module).foregroundStyle(AppColor.textSecondary)
            } else {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(data.selected.entries) { entry in
                        HistoryEntryRowView(entry: entry, edit: {
                            editedID = entry.id
                            viewModel.edit(id: entry.id)
                        }, delete: {
                            if viewModel.delete(id: entry.id) {
                                focusedEntry = nil
                            }
                        })
                        .accessibilityFocused($focusedEntry, equals: entry.id)
                    }
                }
            }
            if data.selected.canConfirmNoPoop {
                Button(action: confirmNoPoop) {
                    Text("checkIn.confirmPast", bundle: .module)
                        .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
                }
                .buttonStyle(.bordered)
            }
            Button(action: viewModel.addEntry) {
                Label {
                    Text("history.addEntry", bundle: .module)
                } icon: {
                    Image(systemName: "plus")
                }
                .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
            }
            .buttonStyle(.borderedProminent)
            if viewModel.feedback != nil, data.canUndo {
                Button(action: viewModel.undo) { Text("diary.undo", bundle: .module) }
                    .frame(minHeight: Spacing.touchTarget)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
        .onChange(of: viewModel.errorMessage) { _, error in
            if let error {
                AccessibilityNotification.Announcement(error).post()
            }
        }
        .onChange(of: viewModel.feedback) { _, feedback in
            if let feedback {
                AccessibilityNotification.Announcement(feedback).post()
            }
        }
    }

    @ViewBuilder
    private func marker(_ status: HistoryDayViewData.Status) -> some View {
        switch status {
        case .logged:
            Circle().fill(AppColor.accent)
        case .completed:
            Circle().stroke(AppColor.accent, lineWidth: Spacing.borderWidth)
        case .partial:
            Image(systemName: "diamond.fill").foregroundStyle(AppColor.accent)
        case .unrecorded:
            Capsule().fill(AppColor.textSecondary)
        }
    }

    private func confirmNoPoop() {
        _ = viewModel.confirmNoPoop()
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            legendRow("history.status.logged", marker: "circle.fill")
            legendRow("history.status.completed", marker: "circle")
            legendRow("history.status.partial", marker: "diamond.fill")
            legendRow("history.status.unrecorded", marker: "minus")
        }
        .font(AppFont.caption)
        .foregroundStyle(AppColor.textSecondary)
        .padding(.horizontal, Spacing.sm)
    }

    private var selectedStatus: String {
        let key: String.LocalizationValue = switch data.selected.status {
        case .logged: "history.status.logged"
        case .completed: "history.status.completed"
        case .partial: "history.status.partial"
        case .unrecorded: "history.status.unrecorded"
        }
        return String(localized: key, bundle: .module)
    }

    private func legendRow(_ key: LocalizedStringKey, marker: String) -> some View {
        Label {
            Text(key, bundle: .module)
        } icon: {
            Image(systemName: marker).accessibilityHidden(true)
        }
    }

    private var editorBinding: Binding<EntryEditorViewModel?> {
        Binding(get: { viewModel.editor }, set: {
            if $0 == nil {
                viewModel.dismissEditor()
            }
        })
    }

    private func dismissed() {
        viewModel.dismissEditor()
        focusedEntry = editedID
    }
}
