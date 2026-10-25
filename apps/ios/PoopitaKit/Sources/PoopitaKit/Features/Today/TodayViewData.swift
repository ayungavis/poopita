import Foundation

struct TodayViewData: Equatable, Sendable {
    let dateLabel: String
    let entries: [TodayEntryViewData]
    let canUndo: Bool
}
