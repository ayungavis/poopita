import Foundation

struct TodayHeroStatusViewData: Equatable, Sendable {
    let title: String
    let detail: String?
    let count: Int
    let isRecorded: Bool
    let isConfirmedNoPoop: Bool
    let isPartialCheckIn: Bool
}
