import Foundation

@MainActor
protocol DiaryRepository {
    var canUndo: Bool { get }
    func entries() throws -> [DiaryEntry]
    func checkIns() throws -> [NoPoopCheckIn]
    func saveCheckIn(_ checkIn: NoPoopCheckIn) throws
    @discardableResult
    func save(_ entry: DiaryEntry) throws -> DiaryEntrySaveResult
    func delete(id: UUID) throws
    func deleteAll() throws
    func undo() throws
}

@MainActor
final class LocalDiaryRepository: DiaryRepository {
    private let store: any ValueStore
    private var undoState: (previous: DiarySnapshot, saved: DiarySnapshot)?
    var canUndo: Bool {
        undoState != nil
    }

    init(store: any ValueStore) {
        self.store = store
    }

    func checkIns() throws -> [NoPoopCheckIn] {
        try snapshot().checkIns.sorted { $0.day > $1.day }
    }

    func saveCheckIn(_ checkIn: NoPoopCheckIn) throws {
        try Task.checkCancellation()
        try checkIn.validate()
        let previous = try snapshot()
        guard !previous.entries.contains(where: { DiaryDay(occurrence: $0.occurrence) == checkIn.day }) else {
            throw AppError.checkInConflict
        }
        let updated = DiarySnapshot(
            entries: previous.entries,
            checkIns: previous.checkIns.filter { $0.day != checkIn.day } + [checkIn]
        )
        try store.write(updated, key: "diary")
        undoState = (previous, updated)
    }

    func entries() throws -> [DiaryEntry] {
        try snapshot().entries.sorted {
            if $0.occurrence.instant == $1.occurrence.instant {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.occurrence.instant > $1.occurrence.instant
        }
    }

    @discardableResult
    func save(_ entry: DiaryEntry) throws -> DiaryEntrySaveResult {
        try Task.checkCancellation()
        try entry.validate()
        let previous = try snapshot()
        let retained = previous.checkIns.filter { $0.day != DiaryDay(occurrence: entry.occurrence) }
        let updated = DiarySnapshot(entries: previous.entries.filter { $0.id != entry.id } + [entry], checkIns: retained)
        try store.write(updated, key: "diary")
        undoState = (previous, updated)
        return retained.count == previous.checkIns.count ? .saved : .dayUpdated
    }

    func delete(id: UUID) throws {
        let previous = try snapshot()
        guard previous.entries.contains(where: { $0.id == id }) else { throw AppError.notFound }
        let updated = DiarySnapshot(entries: previous.entries.filter { $0.id != id }, checkIns: previous.checkIns)
        try store.write(updated, key: "diary")
        undoState = (previous, updated)
    }

    func deleteAll() throws {
        let previous = try snapshot()
        let updated = DiarySnapshot(entries: [], checkIns: [])
        try store.write(updated, key: "diary")
        undoState = (previous, updated)
    }

    func undo() throws {
        guard let undoState else { throw AppError.nothingToUndo }
        guard try snapshot() == undoState.saved else { throw AppError.conflict }
        try store.write(undoState.previous, key: "diary")
        self.undoState = nil
    }

    private func snapshot() throws -> DiarySnapshot {
        guard let saved = try store.read(DiarySnapshot.self, key: "diary") else {
            return DiarySnapshot(entries: [], checkIns: [])
        }
        guard Set(saved.entries.map(\.id)).count == saved.entries.count,
              Set(saved.checkIns.map(\.day)).count == saved.checkIns.count,
              !saved.entries.contains(where: { entry in
                  saved.checkIns.contains { $0.day == DiaryDay(occurrence: entry.occurrence) }
              })
        else {
            throw AppError.invalidStoredData
        }
        do {
            try saved.entries.forEach { try $0.validate() }
            try saved.checkIns.forEach { try $0.validate() }
        } catch {
            throw AppError.invalidStoredData
        }
        return saved
    }
}

private struct DiarySnapshot: Codable, Equatable {
    let version: Int
    let entries: [DiaryEntry]
    let checkIns: [NoPoopCheckIn]

    init(entries: [DiaryEntry], checkIns: [NoPoopCheckIn]) {
        version = 2
        self.entries = entries
        self.checkIns = checkIns
    }

    private enum CodingKeys: String, CodingKey {
        case version, entries, checkIns
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .version)
        guard version == 1 || version == 2 else { throw AppError.invalidStoredData }
        let entries = try container.decode([DiaryEntry].self, forKey: .entries)
        if version == 1 {
            guard !container.contains(.checkIns) else { throw AppError.invalidStoredData }
            self.init(entries: entries, checkIns: [])
        } else {
            try self.init(entries: entries, checkIns: container.decode([NoPoopCheckIn].self, forKey: .checkIns))
        }
    }
}
