import DesignSystem
import SwiftUI

struct DayMarkView: View {
    let mark: DayMarkViewData
    let isSelected: Bool

    var body: some View {
        switch mark {
        case let .logs(count):
            HStack(spacing: Spacing.xs) {
                ForEach(0 ..< min(count, 3), id: \.self) { _ in
                    Circle().fill(isSelected ? AppColor.onInk : AppColor.marker)
                        .frame(width: Spacing.xs, height: Spacing.xs)
                }
            }
        case .noPoop:
            Circle()
                .stroke(isSelected ? AppColor.onInk : AppColor.textSecondary, lineWidth: Spacing.borderWidth)
                .frame(width: Spacing.sm, height: Spacing.sm)
        case .noneSoFar:
            Rectangle()
                .stroke(isSelected ? AppColor.onInk : AppColor.partial, lineWidth: Spacing.borderWidth)
                .frame(width: Spacing.xs + Spacing.borderWidth * 2, height: Spacing.xs + Spacing.borderWidth * 2)
                .rotationEffect(.degrees(45))
        case .unrecorded:
            HatchView(color: isSelected ? AppColor.onInk : AppColor.marker)
                .frame(width: Spacing.lg, height: Spacing.sm)
                .overlay {
                    RoundedRectangle(cornerRadius: Spacing.borderWidth * 2)
                        .stroke(isSelected ? AppColor.onInk : AppColor.marker, lineWidth: Spacing.borderWidth)
                }
                .clipShape(RoundedRectangle(cornerRadius: Spacing.borderWidth * 2))
        case .future, .open:
            Color.clear.frame(width: Spacing.xs, height: Spacing.xs)
        }
    }
}
