import Foundation
import Observation

@MainActor
@Observable
final class CheckInViewModel {
    private(set) var state: Loadable<CheckInViewData> = .idle
    private(set) var selectedDate: Date
    private(set) var errorMessage: String?
    private let repository: any DiaryRepository
    private let now: () -> Date
    private let timeZone: () -> TimeZone

    init(repository: any DiaryRepository, now: @escaping () -> Date, timeZone: @escaping () -> TimeZone) throws {
        self.repository = repository
        self.now = now
        self.timeZone = timeZone
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone()
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now()) else {
            throw AppError.invalidOccurrence
        }
        selectedDate = yesterday
    }

    func load() throws {
        state = .loading
        do {
            state = try .loaded(Self.viewData(
                entries: repository.entries(), checkIns: repository.checkIns(),
                date: now(), selectedDate: selectedDate, timeZone: timeZone()
            ))
        } catch {
            let failure = AppError(wrapping: error)
            state = .failed(failure)
            throw failure
        }
    }

    func selectDate(_ date: Date) {
        let previous = selectedDate
        selectedDate = date
        do {
            try load()
            errorMessage = nil
        } catch {
            selectedDate = previous
            errorMessage = AppError(wrapping: error).userMessage
        }
    }

    @discardableResult
    func confirmSelectedDay() -> Bool {
        do {
            let report = try OccurrenceTime(instant: now(), timeZone: timeZone())
            let day = try DiaryDay(date: selectedDate, timeZone: timeZone())
            return try save(NoPoopCheckIn(day: day, reportedAt: report, coverage: .completed))
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
            return false
        }
    }

    private func save(_ checkIn: NoPoopCheckIn) throws -> Bool {
        do {
            try Task.checkCancellation()
            try repository.saveCheckIn(checkIn)
            errorMessage = nil
            return true
        } catch is CancellationError {
            return false
        } catch {
            Log.report(error, context: Log.Context(operation: "diary.checkIn"))
            throw error
        }
    }

    static func viewData(
        entries: [DiaryEntry], checkIns: [NoPoopCheckIn], date: Date, selectedDate: Date, timeZone: TimeZone
    ) throws -> CheckInViewData {
        let today = try DiaryDay(date: date, timeZone: timeZone)
        return try CheckInViewData(
            today: dayData(entries: entries, checkIns: checkIns, today: today,
                           date: date, timeZone: timeZone),
            selected: dayData(entries: entries, checkIns: checkIns, today: today,
                              date: selectedDate, timeZone: timeZone)
        )
    }

    private static func dayData(
        entries: [DiaryEntry], checkIns: [NoPoopCheckIn], today: DiaryDay, date: Date, timeZone: TimeZone
    ) throws -> CheckInDayViewData {
        let day = try DiaryDay(date: date, timeZone: timeZone)
        var dateStyle = Date.FormatStyle.dateTime.year().month(.abbreviated).day()
        dateStyle.timeZone = timeZone
        let label = date.formatted(dateStyle)
        if entries.contains(where: { DiaryDay(occurrence: $0.occurrence) == day }) {
            return CheckInDayViewData(dateLabel: label, status: String(localized: "checkIn.hasEntries", bundle: .module),
                                      detail: String(localized: "checkIn.entriesDetail", bundle: .module), canRecord: false)
        }
        guard checkIns.contains(where: { $0.day == day && $0.coverage == .completed }) else {
            return CheckInDayViewData(dateLabel: label, status: String(localized: "checkIn.unknown", bundle: .module),
                                      detail: String(localized: "checkIn.unknownDetail", bundle: .module),
                                      canRecord: day <= today)
        }
        return CheckInDayViewData(dateLabel: label, status: String(localized: "checkIn.completed", bundle: .module),
                                  detail: String(localized: "checkIn.completedDetail", bundle: .module), canRecord: false)
    }
}
