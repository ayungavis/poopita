import DesignSystem
import SwiftUI

struct DayMarkView: View {
    let mark: DayMarkViewData
    let isSelected: Bool
    var isOnTile = false

    var body: some View {
        switch mark {
        case let .logs(count):
            HStack(spacing: Spacing.xs) {
                ForEach(0 ..< min(count, 3), id: \.self) { _ in
                    Circle().fill(isSelected ? AppColor.onInk : isOnTile ? AppColor.accent : AppColor.marker)
                        .frame(width: Spacing.xs, height: Spacing.xs)
                }
            }
        case .noPoop:
            Circle()
                .stroke(isSelected ? AppColor.onInk : AppColor.textSecondary, lineWidth: Spacing.borderWidth)
                .frame(width: Spacing.sm, height: Spacing.sm)
        case .unrecorded where isOnTile:
            Color.clear.frame(width: Spacing.xs, height: Spacing.xs)
        case .unrecorded:
            HatchView(color: isSelected ? AppColor.onInk : AppColor.marker)
                .frame(width: Spacing.lg, height: Spacing.sm)
                .overlay {
                    RoundedRectangle(cornerRadius: Spacing.borderWidth * 2)
                        .stroke(isSelected ? AppColor.onInk : AppColor.marker, lineWidth: Spacing.borderWidth)
                }
                .clipShape(RoundedRectangle(cornerRadius: Spacing.borderWidth * 2))
        case .untracked, .future, .open:
            Color.clear.frame(width: Spacing.xs, height: Spacing.xs)
        }
    }
}
