import Foundation

struct DiaryDay: Codable, Hashable, Comparable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    init(occurrence: OccurrenceTime) {
        year = occurrence.year
        month = occurrence.month
        day = occurrence.day
    }

    init(date: Date, timeZone: TimeZone) throws {
        try self.init(occurrence: OccurrenceTime(instant: date, timeZone: timeZone))
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    func validate() throws {
        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: DateComponents(timeZone: .gmt, year: year, month: month, day: day)),
              try DiaryDay(date: date, timeZone: .gmt) == self
        else { throw AppError.invalidOccurrence }
    }
}
