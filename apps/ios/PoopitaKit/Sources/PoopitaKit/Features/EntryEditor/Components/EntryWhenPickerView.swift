import DesignSystem
import SwiftUI

struct EntryWhenPickerView: View {
    enum Field: Identifiable {
        case date, time

        var id: Self {
            self
        }

        var title: LocalizedStringKey {
            self == .date ? "entry.date" : "entry.time"
        }
    }

    let viewModel: EntryEditorViewModel
    let field: Field
    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat = 0
    @State private var barHeight: CGFloat = 0

    var body: some View {
        NavigationStack {
            picker
                .labelsHidden()
                .environment(\.timeZone, viewModel.displayTimeZone)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.sm)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
                .frame(maxHeight: .infinity, alignment: .top)
                .background {
                    Color.clear
                        .ignoresSafeArea()
                        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { barHeight = $0 }
                }
                .navigationTitle(Text(field.title, bundle: .module))
                .inlineTitle()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button { dismiss() } label: {
                            Text("entry.done", bundle: .module)
                        }
                    }
                }
                .background(AppColor.background)
        }
        .tint(AppColor.accent)
        .presentationDetents(contentHeight > 0 ? [.height(contentHeight + barHeight)] : [.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppColor.background)
    }

    @ViewBuilder private var picker: some View {
        let selection = Binding(get: { viewModel.draft.occurrenceDate }, set: viewModel.setDate)
        switch field {
        case .date:
            DatePicker(selection: selection, in: ...viewModel.maximumDate, displayedComponents: .date) {
                Text(field.title, bundle: .module)
            }
            .datePickerStyle(.graphical)
        case .time:
            DatePicker(selection: selection, in: ...viewModel.maximumDate, displayedComponents: .hourAndMinute) {
                Text(field.title, bundle: .module)
            }
            .wheelStyle()
        }
    }
}

private extension View {
    func inlineTitle() -> some View {
        #if os(iOS)
            navigationBarTitleDisplayMode(.inline)
        #else
            self
        #endif
    }

    func wheelStyle() -> some View {
        #if os(iOS)
            datePickerStyle(.wheel)
        #else
            self
        #endif
    }
}
