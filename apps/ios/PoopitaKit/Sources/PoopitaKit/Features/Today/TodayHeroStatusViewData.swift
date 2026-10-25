import Foundation

struct TodayHeroStatusViewData: Equatable, Sendable {
    let title: String
    let count: Int
    let isRecorded: Bool
    let isConfirmedNoPoop: Bool
    let isPartialCheckIn: Bool
}
