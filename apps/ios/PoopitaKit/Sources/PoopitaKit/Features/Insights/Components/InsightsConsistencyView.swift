import DesignSystem
import SwiftUI

struct InsightsConsistencyView: View {
    let data: InsightsConsistencyViewData
    @ScaledMetric(relativeTo: .caption) private var labelWidth = Spacing.timelineLabel + Spacing.xl + Spacing.xs

    var body: some View {
        CardSectionView("insights.consistency.title") {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if let lead = data.lead {
                    Text(verbatim: lead)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VStack(spacing: Spacing.sm + Spacing.xs / 2) {
                    ForEach(data.rows) { row in
                        rowView(row)
                    }
                }
                .overlay(alignment: .topLeading) { marks.accessibilityHidden(true) }
                .padding(.top, Spacing.lg)
                legend
            }
            .padding(.vertical, Spacing.lg)
        }
    }

    private func rowView(_ row: InsightsShareRowViewData) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(verbatim: row.label)
                .font(AppFont.caption.weight(row.isCurrent ? .semibold : .regular))
                .foregroundStyle(row.isCurrent ? AppColor.textPrimary : AppColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: labelWidth, alignment: .leading)
            Canvas { context, size in
                var start: CGFloat = 0
                let segments = [(row.hard, AppColor.accent), (row.usual, AppColor.track), (row.loose, AppColor.marker)]
                for (share, color) in segments.filter({ $0.0 > 0 }) {
                    let width = CGFloat(share) * size.width
                    let rect = CGRect(x: start + 0.5, y: 0, width: max(width - 1, 1), height: size.height)
                    let path = Path(roundedRect: rect, cornerRadius: 2)
                    context.fill(path, with: .color(color))
                    if color == AppColor.track {
                        context.stroke(path, with: .color(AppColor.marker.opacity(0.5)), lineWidth: Spacing.borderWidth)
                    }
                    start += width
                }
                if start == 0 {
                    context.stroke(
                        Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 2),
                        with: .color(AppColor.hairline), lineWidth: Spacing.borderWidth
                    )
                }
            }
            .frame(height: Spacing.sm + 1)
            .opacity(row.isDimmed ? 0.45 : 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: row.accessibilityLabel))
    }

    private var marks: some View {
        HStack(spacing: Spacing.sm) {
            Color.clear.frame(width: labelWidth)
            GeometryReader { proxy in
                ForEach([0.25, 0.75], id: \.self) { share in
                    VStack(spacing: Spacing.xs / 2) {
                        Text(verbatim: "25%")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize()
                        Rectangle()
                            .fill(AppColor.ink.opacity(0.6))
                            .frame(width: Spacing.borderWidth)
                    }
                    .frame(height: proxy.size.height + Spacing.lg)
                    .position(x: proxy.size.width * share, y: (proxy.size.height + Spacing.lg) / 2 - Spacing.lg)
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: Spacing.md) {
            swatch(AppColor.accent, "insights.consistency.hard")
            swatch(AppColor.track, "insights.consistency.usual")
            swatch(AppColor.marker, "insights.consistency.looseLabel")
        }
        .font(AppFont.caption)
        .foregroundStyle(AppColor.textSecondary)
        .accessibilityElement(children: .combine)
    }

    private func swatch(_ color: Color, _ title: LocalizedStringKey) -> some View {
        HStack(spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: 2).fill(color)
                .overlay { RoundedRectangle(cornerRadius: 2).stroke(AppColor.marker.opacity(0.5), lineWidth: Spacing.borderWidth)
                }
                .frame(width: Spacing.sm + 2, height: Spacing.sm + 2)
            Text(title, bundle: .module)
        }
    }
}
