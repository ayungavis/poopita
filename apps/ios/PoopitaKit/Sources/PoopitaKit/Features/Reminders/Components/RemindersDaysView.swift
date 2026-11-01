import DesignSystem
import SwiftUI

struct RemindersDaysView: View {
    let days: [RemindersDayViewData]
    let toggle: (Int) -> Void

    var body: some View {
        ScrollView {
            CardSectionView(nil) {
                ForEach(days) { day in
                    if day.id != days.first?.id {
                        CardDividerView()
                    }
                    Button { toggle(day.id) } label: {
                        HStack {
                            Text(verbatim: day.title)
                            Spacer()
                            if day.isOn {
                                Image(systemName: "checkmark")
                                    .font(AppFont.body.weight(.semibold))
                                    .foregroundStyle(AppColor.ink)
                            }
                        }
                        .cardRow()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(day.isOn ? .isSelected : [])
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
        }
        .background(AppColor.background)
        .navigationTitle(Text("reminders.days", bundle: .module))
        .sensoryFeedback(.selection, trigger: days)
    }
}
