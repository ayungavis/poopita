import DesignSystem
import SwiftUI

struct HistoryContentView: View {
    let viewModel: HistoryViewModel
    let data: HistoryViewData
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var headerHeight: CGFloat = 0
    @State private var isHeaderHidden = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HistoryMonthHeaderView(data: data, move: viewModel.moveMonth)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
                if let error = viewModel.errorMessage {
                    Text(verbatim: error).foregroundStyle(AppColor.destructive)
                }
                HistoryCalendarView(data: data.calendar, select: viewModel.select(id:))
                    .simultaneousGesture(monthSwipe)
                HistoryLegendView()
                summary
                HistoryDaySectionView(
                    data: data.selected, edit: viewModel.edit(id:), log: viewModel.addEntry, confirm: confirmNoPoop
                )
                .padding(.top, Spacing.sm)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: data.selected)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > headerHeight
        } action: { _, isHidden in
            isHeaderHidden = isHidden
        }
        .background(AppColor.background)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(verbatim: data.monthLabel)
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .contentTransition(.opacity)
                    .opacity(isHeaderHidden ? 1 : 0)
                    .offset(y: isHeaderHidden || reduceMotion ? 0 : Spacing.sm)
                    .accessibilityHidden(!isHeaderHidden)
                    .animation(.snappy(duration: 0.25), value: isHeaderHidden)
                    .animation(.easeInOut(duration: 0.2), value: data.monthLabel)
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .fullScreenModal(item: editorBinding, onDismiss: viewModel.dismissEditor) { editor in
            EntryEditorView(
                viewModel: editor, saved: viewModel.savedEditor,
                delete: { viewModel.delete(id: editor.id) }, deletionError: viewModel.errorMessage
            )
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            if let error {
                AccessibilityNotification.Announcement(error).post()
            }
        }
    }

    private var summary: some View {
        HStack {
            Text(verbatim: data.logSummary)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
            Spacer(minLength: Spacing.sm)
            if let unrecorded = data.unrecorded {
                Button {
                    viewModel.select(id: unrecorded.dayID)
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Text(verbatim: unrecorded.label)
                        Image(systemName: "chevron.right").accessibilityHidden(true)
                    }
                    .font(AppFont.caption.weight(.semibold))
                    .foregroundStyle(AppColor.accent)
                    .frame(minHeight: Spacing.touchTarget)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var monthSwipe: some Gesture {
        DragGesture(minimumDistance: Spacing.xl).onEnded { value in
            let width = value.translation.width
            guard abs(width) > abs(value.translation.height) * 2 else { return }
            viewModel.moveMonth(width < 0 ? 1 : -1)
        }
    }

    private func confirmNoPoop() {
        _ = viewModel.confirmNoPoop()
    }

    private var editorBinding: Binding<EntryEditorViewModel?> {
        Binding(get: { viewModel.editor }, set: {
            if $0 == nil {
                viewModel.dismissEditor()
            }
        })
    }
}
