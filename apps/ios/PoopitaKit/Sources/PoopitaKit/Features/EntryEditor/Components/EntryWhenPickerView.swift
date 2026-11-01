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
    @State private var height: CGFloat = 0

    var body: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Text(field.title, bundle: .module).font(AppFont.body.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Text("entry.done", bundle: .module).font(AppFont.body.weight(.semibold))
                            .frame(minHeight: Spacing.touchTarget)
                    }
                }
            }
            picker
                .labelsHidden()
                .environment(\.timeZone, viewModel.displayTimeZone)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .tint(AppColor.accent)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        .presentationDetents(height > 0 ? [.height(height)] : [.medium])
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
    func wheelStyle() -> some View {
        #if os(iOS)
            datePickerStyle(.wheel)
        #else
            self
        #endif
    }
}
