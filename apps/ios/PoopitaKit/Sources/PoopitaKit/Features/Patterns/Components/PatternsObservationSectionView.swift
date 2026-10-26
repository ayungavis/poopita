import DesignSystem
import SwiftUI

struct PatternsObservationSectionView: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let data: PatternsObservationSectionViewData

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title, bundle: .module).font(AppFont.title).accessibilityAddTraits(.isHeader)
            Text(detail, bundle: .module).font(AppFont.caption).foregroundStyle(AppColor.textSecondary)
            Text("patterns.observation.recorded \(data.recordedCount), \(data.totalEntries)", bundle: .module)
                .font(AppFont.caption)
            if data.recordedCount > 0 {
                ForEach(data.items) { item in
                    PatternsDistributionRowView(title: item.title, count: item.count, ratio: item.ratio)
                }
            } else {
                Text("patterns.observation.empty", bundle: .module).foregroundStyle(AppColor.textSecondary)
            }
            Text("patterns.observation.missing \(data.missingCount)", bundle: .module)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(Spacing.lg)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
    }
}
