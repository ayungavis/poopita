import Foundation

struct DayMarks {
    let logs: [DiaryDay: [DiaryEntry]]
    let checkIns: [DiaryDay: NoPoopCheckIn]
    let today: DiaryDay

    init(entries: [DiaryEntry], checkIns: [NoPoopCheckIn], today: DiaryDay) {
        logs = Dictionary(grouping: entries) { DiaryDay(occurrence: $0.occurrence) }
        self.checkIns = Dictionary(checkIns.map { ($0.day, $0) }) { first, _ in first }
        self.today = today
    }

    func mark(_ day: DiaryDay) -> DayMarkViewData {
        if let count = logs[day]?.count {
            return .logs(count)
        }
        switch checkIns[day]?.coverage {
        case .completed: return .noPoop
        case .partial: return .noneSoFar
        case nil: return day > today ? .future : day == today ? .open : .unrecorded
        }
    }
}
