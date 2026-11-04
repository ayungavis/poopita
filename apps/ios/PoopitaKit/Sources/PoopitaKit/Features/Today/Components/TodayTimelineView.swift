import DesignSystem
import SwiftUI

struct TodayTimelineView: View {
    let timeline: TodayTimelineViewData
    let startMinute: Int
    let edit: (UUID) -> Void
    let log: () -> Void
    var move: (UUID, Int) -> Bool = { _, _ in false }
    var timeLabel: (Int) -> String = { _ in "" }
    var focusMoved: (CGFloat) -> Void = { _ in }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var hourHeight = Spacing.timelineHour
    @ScaledMetric(relativeTo: .body) private var blockHeight = Spacing.timelineBlock
    @ScaledMetric(relativeTo: .caption) private var labelWidth = Spacing.timelineLabel

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let minute = timeline.blocks.last?.minute ?? timeline.now?.minute {
                Color.clear
                    .frame(height: Spacing.borderWidth)
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.frame(in: .scrollView(axis: .vertical)).minY
                    } action: { focusMoved($0) }
                    .padding(.top, max(0, offset(minute)))
                    .transaction { $0.animation = nil }
            }
            ForEach(timeline.hours.filter { $0.minute >= startMinute }) { hour in
                HStack(spacing: Spacing.sm) {
                    Text(verbatim: hour.label)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: labelWidth, alignment: .leading)
                    Rectangle().fill(AppColor.hairline).frame(height: Spacing.borderWidth)
                }
                .alignmentGuide(VerticalAlignment.top) { $0.height / 2 }
                .offset(y: offset(hour.minute))
            }
            if let since = timeline.sinceLast, let now = timeline.now, fitsSinceCard(now) {
                sinceLastView(since, height: offset(now.minute) - sinceTop).offset(y: sinceTop)
            }
            Group {
                ForEach(Array(zip(timeline.blocks, blockTops)), id: \.0.id) { block, top in
                    TodayTimelineBlockView(
                        block: block, hourHeight: hourHeight, blockHeight: blockHeight,
                        latestMinute: timeline.latestMinute, timeLabel: timeLabel, edit: { edit(block.id) },
                        move: { move(block.id, $0) }
                    )
                    .padding(.leading, labelWidth + Spacing.sm)
                    .offset(y: top)
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: timeline.blocks.map(\.id))
            if let now = timeline.now {
                nowLine(now).offset(y: offset(now.minute))
            }
        }
        .frame(maxWidth: .infinity, minHeight: contentBottom, alignment: .topLeading)
        .padding(.top, Spacing.sm)
    }

    private var blockTops: [CGFloat] {
        timeline.blocks.reduce(into: []) { tops, block in
            let previousBottom = tops.last.map { $0 + blockHeight + Spacing.xs } ?? 0
            tops.append(max(offset(block.minute), previousBottom))
        }
    }

    private var contentBottom: CGFloat {
        max(offset(timeline.endMinute), (blockTops.last ?? 0) + blockHeight)
    }

    private var sinceTop: CGFloat {
        blockTops.last ?? 0
    }

    private func fitsSinceCard(_ now: TodayTimelineMarkViewData) -> Bool {
        offset(now.minute) - sinceTop >= blockHeight * 2 + Spacing.xs
    }

    private func offset(_ minute: Int) -> CGFloat {
        CGFloat(minute - startMinute) * hourHeight / 60
    }

    private func sinceLastView(_ since: TodayTimelineMarkViewData, height: CGFloat) -> some View {
        HStack {
            Text(verbatim: since.label)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
            Button(action: log) {
                Image(systemName: "plus")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(width: Spacing.touchTarget, height: blockHeight)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("tab.log", bundle: .module))
        }
        .padding(.leading, Spacing.md)
        .frame(height: blockHeight)
        .frame(height: height, alignment: .bottom)
        .background(AppColor.track, in: RoundedRectangle(cornerRadius: Spacing.sm))
        .padding(.leading, labelWidth + Spacing.sm)
    }

    private func nowLine(_ now: TodayTimelineMarkViewData) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(verbatim: now.label)
                .font(AppFont.caption.weight(.semibold))
                .foregroundStyle(AppColor.destructive)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: labelWidth - Spacing.sm, alignment: .leading)
            Circle().fill(AppColor.destructive).frame(
                width: Spacing.xs + Spacing.borderWidth,
                height: Spacing.xs + Spacing.borderWidth
            )
            Rectangle().fill(AppColor.ink).frame(height: Spacing.borderWidth)
        }
        .alignmentGuide(VerticalAlignment.top) { $0.height / 2 }
    }
}
