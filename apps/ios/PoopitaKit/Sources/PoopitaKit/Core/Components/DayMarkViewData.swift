import Foundation

enum DayMarkViewData: Equatable, Sendable {
    case logs(Int), noPoop, noneSoFar, unrecorded, future, open
}
