import Foundation

struct HistoryDayViewData: Equatable, Sendable, Identifiable {
    enum Status: Equatable, Sendable {
        case logged
        case completed
        case partial
        case unrecorded
    }

    let dayID: String
    let number: String
    let accessibilityLabel: String
    let status: Status
    var id: String {
        dayID
    }
}
