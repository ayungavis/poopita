import Foundation

struct TodayEntryViewData: Equatable, Sendable, Identifiable {
    let id: UUID
    let dateLabel: String
    let timeLabel: String
    let title: String
    let illustration: EntryIllustrationKind?
    let observations: String
    let details: String
    let note: String
}
