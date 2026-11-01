import Foundation

struct DayMarks {
    let logs: [DiaryDay: [DiaryEntry]]
    let checkIns: [DiaryDay: NoPoopCheckIn]
    let today: DiaryDay
    let firstDay: DiaryDay?

    init(entries: [DiaryEntry], checkIns: [NoPoopCheckIn], today: DiaryDay) {
        logs = Dictionary(grouping: entries) { DiaryDay(occurrence: $0.occurrence) }
        self.checkIns = Dictionary(checkIns.map { ($0.day, $0) }) { first, _ in first }
        self.today = today
        firstDay = (Array(logs.keys) + Array(self.checkIns.keys)).min()
    }

    func mark(_ day: DiaryDay) -> DayMarkViewData {
        if let count = logs[day]?.count {
            return .logs(count)
        }
        switch checkIns[day]?.coverage {
        case .completed: return .noPoop
        case .partial: return .noneSoFar
        case nil:
            if day > today {
                return .future
            }
            if day == today {
                return .open
            }
            return firstDay.map { day < $0 } ?? true ? .untracked : .unrecorded
        }
    }
}
