import Foundation

struct InsightsSource {
    let entries: [DiaryEntry]
    let checkIns: [NoPoopCheckIn]
    let period: InsightsPeriod
    let offset: Int
    let now: Date
    let timeZone: TimeZone
}
