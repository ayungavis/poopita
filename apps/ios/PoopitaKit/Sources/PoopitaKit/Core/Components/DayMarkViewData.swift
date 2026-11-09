import Foundation

enum DayMarkViewData: Equatable, Sendable {
    case logs(Int), noPoop, unrecorded, untracked, future, open
}
