import DesignSystem
import SwiftUI

struct TodayRoutineRingView: View {
    let heroStatus: TodayHeroStatusViewData
    let canCheckIn: Bool
    let onLog: () -> Void
    let onCheckIn: () -> Void

    private let ringDiameter: CGFloat = 170

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .stroke(AppColor.surface, lineWidth: Spacing.sm)
                    .frame(width: ringDiameter, height: ringDiameter)

                Circle()
                    .stroke(ringColor, style: ringStyle)
                    .frame(width: ringDiameter, height: ringDiameter)

                VStack(spacing: Spacing.xs) {
                    centerIcon
                    Text(verbatim: heroStatus.title)
                        .font(AppFont.body.weight(.semibold))
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }
            }
            .frame(width: ringDiameter, height: ringDiameter)
            .padding(.top, Spacing.sm)

            VStack(spacing: Spacing.sm) {
                Button(action: onLog) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "plus")
                        Text("today.hero.logButton", bundle: .module)
                    }
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
                    .background(AppColor.accent, in: Capsule())
                }
                .buttonStyle(.plain)

                if canCheckIn {
                    Button(action: onCheckIn) {
                        Text("today.hero.markNone", bundle: .module)
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.accent)
                            .frame(minHeight: Spacing.touchTarget)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.xl))
    }

    private var ringColor: Color {
        if heroStatus.isRecorded {
            AppColor.accent
        } else if heroStatus.isConfirmedNoPoop {
            AppColor.textSecondary.opacity(0.4)
        } else if heroStatus.isPartialCheckIn {
            AppColor.accent.opacity(0.6)
        } else {
            AppColor.textSecondary.opacity(0.15)
        }
    }

    private var ringStyle: StrokeStyle {
        if heroStatus.isRecorded {
            StrokeStyle(lineWidth: Spacing.sm, lineCap: .round)
        } else if heroStatus.isConfirmedNoPoop || heroStatus.isPartialCheckIn {
            StrokeStyle(lineWidth: Spacing.xs, lineCap: .round, dash: [Spacing.sm, Spacing.xs])
        } else {
            StrokeStyle(lineWidth: Spacing.borderWidth)
        }
    }

    @ViewBuilder
    private var centerIcon: some View {
        if heroStatus.isRecorded {
            Image(systemName: "checkmark.circle.fill")
                .font(AppFont.title)
                .foregroundStyle(AppColor.accent)
        } else if heroStatus.isConfirmedNoPoop {
            Image(systemName: "minus.circle")
                .font(AppFont.title)
                .foregroundStyle(AppColor.textSecondary)
        } else if heroStatus.isPartialCheckIn {
            Image(systemName: "diamond.fill")
                .font(AppFont.title)
                .foregroundStyle(AppColor.accent)
        } else {
            Image(systemName: "sparkles")
                .font(AppFont.title)
                .foregroundStyle(AppColor.accent.opacity(0.7))
        }
    }
}
