import Foundation

enum InsightsPeriod: CaseIterable, Equatable, Sendable {
    case week, month, year

    var component: Calendar.Component {
        switch self {
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }
}
