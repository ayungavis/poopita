import DesignSystem
import SwiftUI

struct InsightsFlagsView: View {
    let flags: [InsightsFlagViewData]
    let isDoctor: Bool
    let export: SettingsExportViewData?
    let openDay: (String) -> Void

    var body: some View {
        CardSectionView(isDoctor ? "insights.doctor.title" : "insights.change.title") {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(flags) { flag in
                    if flag.id != flags.first?.id {
                        CardDividerView()
                    }
                    item(flag)
                }
                if let export {
                    ShareLink(item: export, preview: SharePreview(Text("settings.data.exportPDF", bundle: .module))) {
                        Text("insights.doctor.export", bundle: .module)
                            .font(AppFont.body.weight(.medium))
                            .foregroundStyle(AppColor.textPrimary)
                            .padding(.horizontal, Spacing.lg)
                            .frame(minHeight: Spacing.touchTarget)
                            .background(AppColor.track, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, Spacing.lg)
        }
    }

    private func item(_ flag: InsightsFlagViewData) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                if isDoctor {
                    Circle().fill(AppColor.destructive).frame(width: Spacing.sm + Spacing.xs / 2)
                        .accessibilityHidden(true)
                }
                Text(verbatim: flag.title)
                    .font(AppFont.body.weight(.medium))
                    .foregroundStyle(isDoctor ? AppColor.destructive : AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }
            Text(verbatim: flag.detail)
                .font(AppFont.caption)
                .foregroundStyle(isDoctor ? AppColor.textPrimary : AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if !isDoctor, let dayID = flag.dayID {
                Button { openDay(dayID) } label: {
                    Text("insights.change.seeDays", bundle: .module)
                        .font(AppFont.caption.weight(.semibold))
                        .foregroundStyle(AppColor.accent)
                        .frame(minHeight: Spacing.touchTarget, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, -Spacing.md)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
