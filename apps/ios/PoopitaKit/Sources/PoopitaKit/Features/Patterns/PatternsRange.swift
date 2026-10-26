import Foundation

enum PatternsRange: Int, CaseIterable, Equatable, Sendable {
    case oneDay = 1
    case sevenDays = 7
    case fourWeeks = 28
    case oneYear = 366

    var dayCount: Int? {
        switch self {
        case .oneDay: 1
        case .sevenDays: 7
        case .fourWeeks: 28
        case .oneYear: nil
        }
    }

    var displayKey: String {
        switch self {
        case .oneDay: "patterns.range.oneDay"
        case .sevenDays: "patterns.range.sevenDays"
        case .fourWeeks: "patterns.range.fourWeeks"
        case .oneYear: "patterns.range.oneYear"
        }
    }
}
