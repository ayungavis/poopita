import DesignSystem
import SwiftUI

struct InsightsWhenChartView: View {
    let data: InsightsWhenViewData
    @State private var selectedID: String?
    @ScaledMetric(relativeTo: .body) private var height = Spacing.chartHeight

    var body: some View {
        VStack(spacing: Spacing.sm) {
            if data.columns.contains(where: { $0.cell != nil }) {
                HStack(spacing: 0) {
                    ForEach(data.columns) { column in
                        if let cell = column.cell {
                            InsightsDayCellView(cell: cell, isSelected: column.id == selectedID)
                        }
                    }
                }
            }
            chart
            if data.columns.contains(where: { $0.label != nil }) {
                HStack(spacing: 0) {
                    ForEach(data.columns) { column in
                        Text(verbatim: column.label ?? "")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize()
                            .frame(maxWidth: .infinity)
                    }
                }
                .accessibilityHidden(true)
            }
        }
        .onChange(of: data) { selectedID = nil }
        .sensoryFeedback(.selection, trigger: selectedID)
    }

    private var chart: some View {
        HStack(spacing: 0) {
            ForEach(Array(data.columns.enumerated()), id: \.element.id) { index, column in
                columnView(column, alignment: InsightsBubbleView.alignment(at: index, of: data.columns.count))
                    .zIndex(column.id == selectedID ? 1 : 0)
            }
        }
        .frame(height: height)
        .background(alignment: .topLeading) { hourLines }
    }

    private var hourLines: some View {
        ZStack(alignment: .topLeading) {
            ForEach(data.hourMarks) { mark in
                HStack(spacing: Spacing.xs) {
                    Text(verbatim: mark.label)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize()
                    Rectangle().fill(AppColor.hairline).frame(height: Spacing.borderWidth)
                }
                .alignmentGuide(.top) { $0.height / 2 }
                .offset(y: offset(mark.minute))
            }
        }
        .padding(.leading, -Spacing.lg)
        .accessibilityHidden(true)
    }

    private func columnView(_ column: InsightsColumnViewData, alignment: Alignment) -> some View {
        let isSelected = column.id == selectedID
        return Button {
            selectedID = isSelected ? nil : column.id
        } label: {
            ZStack(alignment: .top) {
                if column.isUnrecorded {
                    HatchView(color: AppColor.marker.opacity(0.5))
                } else if column.isToday {
                    RoundedRectangle(cornerRadius: Spacing.md).fill(AppColor.track)
                }
                Canvas { context, size in
                    draw(column, in: &context, size: size)
                }
            }
            .padding(.horizontal, data.columns.count > 7 ? Spacing.borderWidth : Spacing.xs)
            .contentShape(Rectangle())
            .overlay(alignment: alignment) {
                if isSelected {
                    InsightsBubbleView(text: column.summary).offset(y: Spacing.sm)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: column.summary))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func draw(_ column: InsightsColumnViewData, in context: inout GraphicsContext, size: CGSize) {
        let isThin = data.columns.count > 7
        let blockHeight = isThin ? Spacing.xs : Spacing.sm
        let inset = isThin ? 0 : Spacing.xs
        for minute in column.logMinutes {
            let rect = CGRect(
                x: inset, y: y(minute, in: size) - blockHeight / 2,
                width: max(Spacing.borderWidth * 2, size.width - inset * 2), height: blockHeight
            )
            context.fill(Path(roundedRect: rect, cornerRadius: blockHeight / 2), with: .color(AppColor.marker))
        }
        if let minute = column.checkInMinute {
            let center = CGPoint(x: size.width / 2, y: y(minute, in: size))
            var diamond = Path()
            diamond.move(to: CGPoint(x: center.x, y: center.y - Spacing.sm))
            diamond.addLine(to: CGPoint(x: center.x + Spacing.sm, y: center.y))
            diamond.addLine(to: CGPoint(x: center.x, y: center.y + Spacing.sm))
            diamond.addLine(to: CGPoint(x: center.x - Spacing.sm, y: center.y))
            diamond.closeSubpath()
            context.stroke(diamond, with: .color(AppColor.partial), lineWidth: Spacing.borderWidth)
        }
        if let minute = column.nowMinute, minute >= data.startMinute, minute <= data.endMinute {
            let lineY = y(minute, in: size)
            var line = Path()
            line.move(to: CGPoint(x: 0, y: lineY))
            line.addLine(to: CGPoint(x: size.width, y: lineY))
            context.stroke(line, with: .color(AppColor.destructive), lineWidth: Spacing.borderWidth * 2)
            context.fill(
                Path(ellipseIn: CGRect(x: -Spacing.xs, y: lineY - Spacing.xs, width: Spacing.sm, height: Spacing.sm)),
                with: .color(AppColor.destructive)
            )
        }
    }

    private func y(_ minute: Int, in size: CGSize) -> CGFloat {
        CGFloat(minute - data.startMinute) / CGFloat(max(1, data.endMinute - data.startMinute)) * size.height
    }

    private func offset(_ minute: Int) -> CGFloat {
        CGFloat(minute - data.startMinute) / CGFloat(max(1, data.endMinute - data.startMinute)) * height
    }
}
