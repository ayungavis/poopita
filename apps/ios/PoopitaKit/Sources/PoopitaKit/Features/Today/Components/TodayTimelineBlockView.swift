import DesignSystem
import SwiftUI

struct TodayTimelineBlockView: View {
    let block: TodayTimelineBlockViewData
    let hourHeight: CGFloat
    let blockHeight: CGFloat
    let latestMinute: Int
    let timeLabel: (Int) -> String
    let edit: () -> Void
    let move: (Int) -> Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var dragHeight: CGFloat?
    @State private var droppedMinute: Int?
    @State private var wasLifted = false

    private var isLifted: Bool {
        dragHeight != nil
    }

    private var proposedMinute: Int? {
        dragHeight.map(minute(movedBy:))
    }

    private var shownMinute: Int {
        proposedMinute ?? droppedMinute ?? block.minute
    }

    private var isPastLimit: Bool {
        shownMinute > latestMinute
    }

    var body: some View {
        ZStack {
            details.opacity(isLifted ? 0 : 1)
            if isLifted {
                bubble
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: blockHeight)
        .background(AppColor.entry, in: RoundedRectangle(cornerRadius: Spacing.sm))
        .overlay {
            if isLifted {
                RoundedRectangle(cornerRadius: Spacing.sm)
                    .strokeBorder(AppColor.surface, lineWidth: Spacing.borderWidth * 2)
            }
        }
        .contentShape(Rectangle())
        .scaleEffect(isLifted && !reduceMotion ? 1.02 : 1)
        .rotationEffect(.degrees(isLifted && !reduceMotion ? 1.1 : 0))
        .shadow(color: AppColor.ink.opacity(isLifted ? 0.18 : 0), radius: Spacing.md, y: Spacing.sm)
        .offset(y: CGFloat(shownMinute - block.minute) * hourHeight / 60)
        .zIndex(isLifted ? 1 : 0)
        .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: isLifted)
        .gesture(dragToMove)
        .simultaneousGesture(TapGesture().onEnded {
            if wasLifted {
                wasLifted = false
            } else {
                edit()
            }
        })
        .sensoryFeedback(.selection, trigger: proposedMinute) { _, new in new != nil }
        .sensoryFeedback(.impact(weight: .medium), trigger: isLifted) { _, lifted in lifted }
        .onChange(of: block.minute) { droppedMinute = nil }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: [block.entry.timeLabel, block.entry.observations].joined(separator: ", ")))
        .accessibilityHint(Text("entry.editHint", bundle: .module))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, edit)
    }

    private var details: some View {
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
    }

    private var bubble: some View {
        Text(verbatim: isPastLimit
            ? String(localized: "today.moveLimit \(timeLabel(latestMinute))", bundle: .module)
            : timeLabel(shownMinute))
            .font(AppFont.caption.weight(.semibold))
            .foregroundStyle(AppColor.onInk)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(isPastLimit ? AppColor.destructive : AppColor.ink, in: Capsule())
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func minute(movedBy height: CGFloat) -> Int {
        let steps = (Double(height / hourHeight) * 60 / 5).rounded()
        return min(max(block.minute + Int(steps) * 5, 0), 24 * 60 - 1)
    }

    private var dragToMove: some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .updating($dragHeight) { value, state, _ in
                if case let .second(true, drag) = value {
                    state = drag?.translation.height ?? 0
                }
            }
            .onChanged { value in
                if case .second(true, _) = value, !wasLifted {
                    wasLifted = true
                }
            }
            .onEnded { value in
                guard case let .second(true, drag?) = value else { return }
                if abs(drag.translation.height) > Spacing.sm {
                    wasLifted = false
                }
                let minute = minute(movedBy: drag.translation.height)
                guard minute != block.minute, minute <= latestMinute else { return }
                droppedMinute = minute
                if !move(minute) {
                    droppedMinute = nil
                }
            }
    }
}
