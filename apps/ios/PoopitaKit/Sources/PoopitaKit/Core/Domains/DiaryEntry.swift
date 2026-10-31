import Foundation

struct DiaryEntry: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let occurrence: OccurrenceTime
    let stoolType: Int?
    let amount: Amount?
    let effort: Effort?
    let blood: Blood?
    let color: StoolColor?
    let duration: Duration?
    let note: String

    enum Amount: String, Codable, Sendable, CaseIterable {
        case verySmall, small, medium, large, veryLarge
    }

    enum Effort: String, Codable, Sendable, CaseIterable {
        case easy, moderate, difficult
    }

    enum Blood: String, Codable, Sendable, CaseIterable {
        case none, seen
    }

    enum StoolColor: String, Codable, Sendable, CaseIterable {
        case pale, yellow, tan, orange, brown, green, black, red
    }

    enum Duration: String, Codable, Sendable, CaseIterable {
        case underTwo, twoToFive, fiveToTen, overTen
    }

    init(
        id: UUID, occurrence: OccurrenceTime, stoolType: Int?, amount: Amount?, effort: Effort?,
        blood: Blood? = nil, color: StoolColor? = nil, duration: Duration? = nil, note: String
    ) {
        self.id = id
        self.occurrence = occurrence
        self.stoolType = stoolType
        self.amount = amount
        self.effort = effort
        self.blood = blood
        self.color = color
        self.duration = duration
        self.note = note
    }

    func validate() throws {
        try occurrence.validate()
        guard stoolType.map({ (1 ... 7).contains($0) }) ?? true else { throw AppError.invalidObservation }
        guard note.count <= 500 else { throw AppError.noteTooLong }
    }
}
