import DesignSystem
import SwiftUI

struct PatternsDayDetailSectionView: View {
    let days: [PatternsDayDetailViewData]
    @Binding var selectedDayID: String?

    private var selectedIndex: Int {
        days.firstIndex(where: { $0.dayID == selectedDayID }) ?? max(0, days.count - 1)
    }

    var body: some View {
        if !days.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("patterns.detail.title", bundle: .module)
                    .font(AppFont.title)
                    .accessibilityAddTraits(.isHeader)
                HStack {
                    Button { select(offset: -1) } label: { Image(systemName: "chevron.left") }
                        .frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
                        .accessibilityLabel(Text("patterns.detail.previous", bundle: .module))
                        .disabled(selectedIndex == 0)
                    Spacer()
                    Picker(selection: dayBinding) {
                        ForEach(days) { day in Text(verbatim: day.dateLabel).tag(day.dayID) }
                    } label: { Text("patterns.detail.day", bundle: .module) }
                        .pickerStyle(.menu)
                    Spacer()
                    Button { select(offset: 1) } label: { Image(systemName: "chevron.right") }
                        .frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
                        .accessibilityLabel(Text("patterns.detail.next", bundle: .module))
                        .disabled(selectedIndex == days.count - 1)
                }
                detail(days[selectedIndex])
            }
            .padding(Spacing.lg)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
        }
    }

    private var dayBinding: Binding<String> {
        Binding(get: { days.isEmpty ? "" : days[selectedIndex].dayID }, set: { selectedDayID = $0 })
    }

    private func select(offset: Int) {
        let index = selectedIndex + offset
        guard days.indices.contains(index) else { return }
        selectedDayID = days[index].dayID
    }

    private func detail(_ day: PatternsDayDetailViewData) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(verbatim: day.statusLabel).font(AppFont.body.weight(.semibold))
            if day.entries.isEmpty {
                Text("patterns.dayDetail.noEntries", bundle: .module)
                    .foregroundStyle(AppColor.textSecondary)
            } else {
                ForEach(day.entries) { entry in PatternsDayEntryRowView(entry: entry) }
            }
        }
    }
}
