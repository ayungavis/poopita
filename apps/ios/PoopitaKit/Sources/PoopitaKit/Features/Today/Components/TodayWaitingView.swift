import DesignSystem
import SwiftUI

struct TodayWaitingView: View {
    let headline: String
    let detail: String?
    let partialNote: String?
    let hours: [TodayTimelineHourViewData]
    let nowMinute: Int
    let checkIn: () -> Void
    @ScaledMetric(relativeTo: .body) private var hourHeight = Spacing.timelineHour
    @ScaledMetric(relativeTo: .caption) private var labelWidth = Spacing.timelineLabel

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            ZStack(alignment: .topLeading) {
                ForEach(hours.filter { $0.minute < nowMinute }) { hour in
                    Text(verbatim: hour.label)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .alignmentGuide(VerticalAlignment.top) { $0.height / 2 }
                        .offset(y: CGFloat(hour.minute) * hourHeight / 60)
                }
            }
            .frame(width: labelWidth, alignment: .topLeading)
            hero
                .frame(maxWidth: .infinity, minHeight: CGFloat(nowMinute) * hourHeight / 60, alignment: .bottomLeading)
                .background(AppColor.track, in: RoundedRectangle(cornerRadius: Spacing.sm))
        }
        .padding(.top, Spacing.sm)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(verbatim: headline)
                .font(AppFont.display)
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if let detail {
                Text(verbatim: detail)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            if let partialNote {
                HStack(spacing: Spacing.sm) {
                    DayMarkView(mark: .noneSoFar, isSelected: false)
                    Text(verbatim: partialNote)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .padding(.top, Spacing.sm)
            } else {
                Button(action: checkIn) {
                    Text("today.notYet", bundle: .module)
                        .font(AppFont.body.weight(.medium))
                        .foregroundStyle(AppColor.textPrimary)
                        .padding(.horizontal, Spacing.xl)
                        .frame(minHeight: Spacing.buttonHeight)
                        .background(AppColor.partial.opacity(0.35), in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.lg)
        .accessibilityElement(children: .contain)
    }
}
