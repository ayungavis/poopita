import DesignSystem
import SwiftUI

struct CheckInView: View {
    @State private var viewModel: CheckInViewModel
    let saved: () -> Void

    init(viewModel: CheckInViewModel, saved: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.saved = saved
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            if let data = viewModel.data {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("checkIn.today", bundle: .module).font(AppFont.body.weight(.semibold)).accessibilityAddTraits(.isHeader)
                    Text(verbatim: data.today.status).font(AppFont.body.weight(.semibold))
                    Text(verbatim: data.today.detail).foregroundStyle(AppColor.textSecondary)
                    if data.today.canRecord {
                        Button {
                            if viewModel.recordToday() {
                                saved()
                            }
                        } label: {
                            Text("checkIn.markToday", bundle: .module)
                        }
                        .frame(minHeight: Spacing.touchTarget)
                    }
                }
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        DatePicker(
                            selection: Binding(get: { viewModel.selectedDate }, set: viewModel.selectDate),
                            in: ...viewModel.maximumDate, displayedComponents: [.date]
                        ) {
                            Text("checkIn.date", bundle: .module)
                        }
                        .environment(\.timeZone, viewModel.displayTimeZone)
                        Text(verbatim: data.selected.dateLabel).font(AppFont.body.weight(.semibold))
                        Text(verbatim: data.selected.status)
                        Text(verbatim: data.selected.detail).foregroundStyle(AppColor.textSecondary)
                        if data.selected.canRecord {
                            Button {
                                if viewModel.confirmSelectedDay() {
                                    saved()
                                }
                            } label: {
                                Text("checkIn.confirmPast", bundle: .module)
                            }
                            .frame(minHeight: Spacing.touchTarget)
                        }
                    }
                    .padding(.top, Spacing.md)
                } label: {
                    Text("checkIn.pastDay", bundle: .module).font(AppFont.body.weight(.semibold))
                }
            }
            if let error = viewModel.errorMessage {
                Text(verbatim: error).foregroundStyle(AppColor.destructive)
            }
        }
        .padding(Spacing.lg)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                AccessibilityNotification.Announcement(message).post()
            }
        }
    }
}
