import Foundation
import Observation

@MainActor
@Observable
final class InsightsViewModel {
    private(set) var state: Loadable<InsightsViewData> = .idle
    private(set) var period: InsightsPeriod = .week
    private(set) var offset = 0
    private(set) var loadTask: Task<Void, Never>?
    private let repository: any DiaryRepository
    private let now: () -> Date
    private let timeZone: () -> TimeZone

    init(repository: any DiaryRepository, now: @escaping () -> Date, timeZone: @escaping () -> TimeZone) {
        self.repository = repository
        self.now = now
        self.timeZone = timeZone
    }

    func select(_ period: InsightsPeriod) {
        guard period != self.period else { return }
        self.period = period
        offset = 0
        load()
    }

    func move(_ amount: Int) {
        let next = min(0, offset + amount)
        guard next != offset else { return }
        offset = next
        load()
    }

    func load() {
        loadTask?.cancel()
        let previousState = state
        let key = (period, offset)
        if case .loaded = state {} else {
            state = .loading
        }
        loadTask = Task {
            do {
                try Task.checkCancellation()
                let entries = try repository.entries()
                let checkIns = try repository.checkIns()
                try Task.checkCancellation()
                state = try .loaded(Self.viewData(InsightsSource(
                    entries: entries, checkIns: checkIns, period: key.0, offset: key.1, now: now(),
                    timeZone: timeZone()
                )))
            } catch is CancellationError {
                guard period == key.0, offset == key.1 else { return }
                state = previousState
            } catch {
                guard !Task.isCancelled, period == key.0, offset == key.1 else { return }
                Log.report(error, context: Log.Context(operation: "insights.load"))
                state = .failed(AppError(wrapping: error))
            }
        }
    }
}
