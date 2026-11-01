import DesignSystem
import SwiftUI

struct InsightsUsualView: View {
    let data: InsightsUsualViewData

    var body: some View {
        CardSectionView("insights.usual.title") {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                ForEach(data.rows) { row in
                    rowView(row)
                }
                Text(verbatim: data.note)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Spacing.lg)
        }
    }

    private func rowView(_ row: InsightsUsualRowViewData) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text(verbatim: row.label)
                    Spacer(minLength: Spacing.sm)
                    value(row)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(verbatim: row.label)
                    value(row)
                }
            }
            band(row)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: row.label + ", " + row.value))
    }

    private func value(_ row: InsightsUsualRowViewData) -> some View {
        Text(verbatim: row.value)
            .font(AppFont.caption)
            .foregroundStyle(AppColor.textSecondary)
    }

    private func band(_ row: InsightsUsualRowViewData) -> some View {
        Canvas { context, size in
            let mid = size.height / 2
            let track = CGRect(x: 0, y: mid - Spacing.xs / 2 - 1, width: size.width, height: Spacing.xs + 2)
            context.fill(Path(roundedRect: track, cornerRadius: track.height / 2), with: .color(AppColor.track))
            let lower = clamp(row.lower) * size.width
            let upper = max(clamp(row.upper) * size.width, lower + Spacing.xs)
            let band = CGRect(x: lower, y: track.minY, width: upper - lower, height: track.height)
            context.fill(Path(roundedRect: band, cornerRadius: track.height / 2), with: .color(AppColor.marker))
            let center = CGPoint(x: min(max(clamp(row.current) * size.width, Spacing.sm), size.width - Spacing.sm), y: mid)
            let dot = CGRect(x: center.x - Spacing.sm + 2, y: mid - Spacing.sm + 2, width: Spacing.md, height: Spacing.md)
            context.fill(Path(ellipseIn: dot.insetBy(dx: -2, dy: -2)), with: .color(AppColor.surface))
            context.fill(Path(ellipseIn: dot), with: .color(AppColor.ink))
        }
        .frame(height: Spacing.lg)
        .accessibilityHidden(true)
    }

    private func clamp(_ value: Double) -> CGFloat {
        CGFloat(min(max(value, 0), 1))
    }
}
