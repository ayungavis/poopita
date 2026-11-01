import Foundation

struct HistorySourceData {
    let entries: [DiaryEntry]
    let checkIns: [NoPoopCheckIn]
    let month: Date
    let selectedDay: DiaryDay
    let today: Date
    let timeZone: TimeZone
}
