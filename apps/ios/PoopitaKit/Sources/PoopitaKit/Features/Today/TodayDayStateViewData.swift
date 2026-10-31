import Foundation

enum TodayDayStateViewData: Equatable, Sendable {
    case logged
    case waiting(headline: String, detail: String?, partialNote: String?)
    case pastDay(status: String, detail: String, logLabel: String, canConfirm: Bool)
}
