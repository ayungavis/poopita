import Foundation

struct DiaryEntry: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let occurrence: OccurrenceTime
    let stoolType: Int?
    let amount: Amount?
    let effort: Effort?
    let note: String

    enum Amount: String, Codable, Sendable, CaseIterable {
        case verySmall, small, medium, large, veryLarge
    }

    enum Effort: String, Codable, Sendable, CaseIterable {
        case easy, moderate, difficult
    }

    func validate() throws {
        try occurrence.validate()
        guard stoolType.map({ (1 ... 7).contains($0) }) ?? true else { throw AppError.invalidObservation }
        guard note.count <= 500 else { throw AppError.noteTooLong }
    }
}
