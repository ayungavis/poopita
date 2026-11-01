import DesignSystem
import SwiftUI

struct TodayTimelineView: View {
    let timeline: TodayTimelineViewData
    let startMinute: Int
    let edit: (UUID) -> Void
    let log: () -> Void
    @ScaledMetric(relativeTo: .body) private var hourHeight = Spacing.timelineHour
    @ScaledMetric(relativeTo: .body) private var blockHeight = Spacing.timelineBlock
    @ScaledMetric(relativeTo: .caption) private var labelWidth = Spacing.timelineLabel

    static let focusID = "today.timeline.focus"

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let minute = timeline.blocks.last?.minute ?? timeline.now?.minute {
                Color.clear
                    .frame(height: Spacing.borderWidth)
                    .padding(.top, max(0, offset(minute)))
                    .id(Self.focusID)
            }
            ForEach(timeline.hours.filter { $0.minute >= startMinute }) { hour in
                HStack(spacing: Spacing.sm) {
                    Text(verbatim: hour.label)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(width: labelWidth, alignment: .leading)
                    Rectangle().fill(AppColor.hairline).frame(height: Spacing.borderWidth)
                }
                .alignmentGuide(VerticalAlignment.top) { $0.height / 2 }
                .offset(y: offset(hour.minute))
            }
            if let since = timeline.sinceLast, let now = timeline.now {
                sinceLastView(since, height: sinceBottom(now) - sinceTop).offset(y: sinceTop)
            }
            ForEach(Array(zip(timeline.blocks, blockTops)), id: \.0.id) { block, top in
                blockButton(block).offset(y: top)
            }
            if timeline.sinceLast != nil, let now = timeline.now {
                nowLine(now).offset(y: sinceBottom(now))
            } else if let now = timeline.now {
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
        var bottom = max(offset(timeline.endMinute), (blockTops.last ?? 0) + blockHeight)
        if timeline.sinceLast != nil, let now = timeline.now {
            bottom = max(bottom, sinceBottom(now))
        }
        return bottom
    }

    private var sinceTop: CGFloat {
        blockTops.last ?? 0
    }

    private func sinceBottom(_ now: TodayTimelineMarkViewData) -> CGFloat {
        max(offset(now.minute), sinceTop + blockHeight * 2 + Spacing.xs)
    }

    private func offset(_ minute: Int) -> CGFloat {
        CGFloat(minute - startMinute) * hourHeight / 60
    }

    private func blockButton(_ block: TodayTimelineBlockViewData) -> some View {
        Button {
            edit(block.id)
        } label: {
            HStack(spacing: Spacing.sm) {
                if let illustration = block.entry.illustration {
                    EntryIllustrationView(kind: illustration)
                        .frame(height: blockHeight - Spacing.sm)
                }
                Text(verbatim: block.entry.title)
                    .font(AppFont.body.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: Spacing.sm)
                Text(verbatim: block.entry.timeLabel)
                    .font(AppFont.caption)
            }
            .foregroundStyle(AppColor.textPrimary)
            .padding(.horizontal, Spacing.md)
            .frame(height: blockHeight)
            .background(AppColor.entry, in: RoundedRectangle(cornerRadius: Spacing.sm))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, labelWidth + Spacing.sm)
        .accessibilityLabel(Text(verbatim: [block.entry.timeLabel, block.entry.observations].joined(separator: ", ")))
        .accessibilityHint(Text("entry.editHint", bundle: .module))
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
