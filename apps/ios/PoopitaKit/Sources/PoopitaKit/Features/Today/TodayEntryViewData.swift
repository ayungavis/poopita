import Foundation

struct TodayEntryViewData: Equatable, Sendable, Identifiable {
    let id: UUID
    let dateLabel: String
    let timeLabel: String
    let observations: String
    let note: String
}
