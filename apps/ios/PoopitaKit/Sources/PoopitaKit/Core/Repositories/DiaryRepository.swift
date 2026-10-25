import Foundation

@MainActor
protocol DiaryRepository {
    var canUndo: Bool { get }
    func entries() throws -> [DiaryEntry]
    func save(_ entry: DiaryEntry) throws
    func delete(id: UUID) throws
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

    func entries() throws -> [DiaryEntry] {
        try snapshot().entries.sorted {
            if $0.occurrence.instant == $1.occurrence.instant {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.occurrence.instant > $1.occurrence.instant
        }
    }

    func save(_ entry: DiaryEntry) throws {
        try entry.validate()
        let previous = try snapshot()
        let updated = DiarySnapshot(version: 1, entries: previous.entries.filter { $0.id != entry.id } + [entry])
        try store.write(updated, key: "diary")
        undoState = (previous, updated)
    }

    func delete(id: UUID) throws {
        let previous = try snapshot()
        guard previous.entries.contains(where: { $0.id == id }) else { throw AppError.notFound }
        let updated = DiarySnapshot(version: 1, entries: previous.entries.filter { $0.id != id })
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
            return DiarySnapshot(version: 1, entries: [])
        }
        guard saved.version == 1, Set(saved.entries.map(\.id)).count == saved.entries.count else {
            throw AppError.invalidStoredData
        }
        do {
            try saved.entries.forEach { try $0.validate() }
        } catch {
            throw AppError.invalidStoredData
        }
        return saved
    }
}

private struct DiarySnapshot: Codable, Equatable {
    let version: Int
    let entries: [DiaryEntry]
}
