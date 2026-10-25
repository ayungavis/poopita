import Foundation

struct NoPoopCheckIn: Codable, Equatable, Sendable {
    enum Coverage: String, Codable, Sendable {
        case partial, completed
    }

    let day: DiaryDay
    let reportedAt: OccurrenceTime
    let coverage: Coverage

    func validate() throws {
        try day.validate()
        try reportedAt.validate()
        let reportDay = DiaryDay(occurrence: reportedAt)
        switch coverage {
        case .partial:
            guard day == reportDay else { throw AppError.invalidCheckIn }
        case .completed:
            guard day < reportDay else { throw AppError.invalidCheckIn }
        }
    }
}
