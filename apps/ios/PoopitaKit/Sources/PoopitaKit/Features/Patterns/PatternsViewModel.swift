import Foundation
import Observation

@MainActor
@Observable
final class PatternsViewModel {
    private(set) var state: Loadable<PatternsViewData> = .idle
    private(set) var selectedRange: PatternsRange = .sevenDays
    private(set) var loadTask: Task<Void, Never>?
    private let repository: any DiaryRepository
    private let now: () -> Date
    private let timeZone: () -> TimeZone

    init(repository: any DiaryRepository, now: @escaping () -> Date, timeZone: @escaping () -> TimeZone) {
        self.repository = repository
        self.now = now
        self.timeZone = timeZone
    }

    func selectRange(_ range: PatternsRange) {
        guard range != selectedRange else { return }
        selectedRange = range
        load()
    }

    func load() {
        loadTask?.cancel()
        let previousState = state
        if case let .loaded(data) = state, data.range == selectedRange {} else {
            state = .loading
        }
        let range = selectedRange
        loadTask = Task {
            do {
                try Task.checkCancellation()
                let entries = try repository.entries()
                let checkIns = try repository.checkIns()
                try Task.checkCancellation()
                state = try .loaded(Self.viewData(
                    for: entries, checkIns: checkIns, range: range, today: now(), timeZone: timeZone()
                ))
            } catch is CancellationError {
                guard selectedRange == range else { return }
                if case let .loaded(data) = previousState, data.range == range {
                    state = previousState
                } else {
                    state = .idle
                }
            } catch {
                guard !Task.isCancelled, selectedRange == range else { return }
                Log.report(error, context: Log.Context(operation: "patterns.load"))
                state = .failed(AppError(wrapping: error))
            }
        }
    }
}
