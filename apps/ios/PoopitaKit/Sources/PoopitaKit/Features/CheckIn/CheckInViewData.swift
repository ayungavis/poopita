import Foundation

struct CheckInViewData: Equatable, Sendable {
    let today: CheckInDayViewData
    let selected: CheckInDayViewData
}
