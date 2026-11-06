import Foundation

enum DiaryIntegrity {
    static func check(entries: [DiaryEntry], checkIns: [NoPoopCheckIn]) throws {
        let entryDays = Set(entries.map { DiaryDay(occurrence: $0.occurrence) })
        guard Set(entries.map(\.id)).count == entries.count,
              Set(checkIns.map(\.day)).count == checkIns.count,
              !checkIns.contains(where: { entryDays.contains($0.day) })
        else {
            throw AppError.invalidStoredData
        }
        do {
            try entries.forEach { try $0.validate() }
            try checkIns.forEach { try $0.validate() }
        } catch {
            throw AppError.invalidStoredData
        }
    }
}
