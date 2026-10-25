import Foundation

struct OccurrenceTime: Codable, Equatable, Sendable {
    let instant: Date
    let timeZoneIdentifier: String
    let utcOffsetSeconds: Int
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int

    init(instant: Date, timeZone: TimeZone) throws {
        guard instant.timeIntervalSince1970.isFinite else { throw AppError.invalidOccurrence }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: instant)
        guard let year = parts.year, let month = parts.month, let day = parts.day,
              let hour = parts.hour, let minute = parts.minute, (1 ... 9999).contains(year)
        else { throw AppError.invalidOccurrence }
        self.instant = instant
        timeZoneIdentifier = timeZone.identifier
        utcOffsetSeconds = timeZone.secondsFromGMT(for: instant)
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
    }

    func validate() throws {
        guard let offset = TimeZone(secondsFromGMT: utcOffsetSeconds), !timeZoneIdentifier.isEmpty else {
            throw AppError.invalidStoredData
        }
        let fixed = try OccurrenceTime(instant: instant, timeZone: offset)
        guard fixed.year == year, fixed.month == month, fixed.day == day,
              fixed.hour == hour, fixed.minute == minute
        else { throw AppError.invalidStoredData }
    }
}
