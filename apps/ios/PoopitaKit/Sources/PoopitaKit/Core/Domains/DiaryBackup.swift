import Foundation

struct DiaryBackup: Codable, Equatable, Sendable {
    let createdAt: Date
    let entries: [DiaryEntry]
    let checkIns: [NoPoopCheckIn]
}

struct DiaryMerge: Equatable, Sendable {
    let entries: [DiaryEntry]
    let checkIns: [NoPoopCheckIn]
    let addedEntries: Int
    let addedCheckIns: Int
    let entriesAlreadyHere: Int

    init(entries local: [DiaryEntry], checkIns localCheckIns: [NoPoopCheckIn], backup: DiaryBackup) {
        let localIDs = Set(local.map(\.id))
        let newEntries = backup.entries.filter { !localIDs.contains($0.id) }
        let mergedEntries = local + newEntries
        let entryDays = Set(mergedEntries.map { DiaryDay(occurrence: $0.occurrence) })
        let localDays = Set(localCheckIns.map(\.day))
        let keptCheckIns = localCheckIns.filter { !entryDays.contains($0.day) }
        let newCheckIns = backup.checkIns.filter { !entryDays.contains($0.day) && !localDays.contains($0.day) }
        entries = mergedEntries
        checkIns = keptCheckIns + newCheckIns
        addedEntries = newEntries.count
        addedCheckIns = newCheckIns.count
        entriesAlreadyHere = backup.entries.count - newEntries.count
    }
}
