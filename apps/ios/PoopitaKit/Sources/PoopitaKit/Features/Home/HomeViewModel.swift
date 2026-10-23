import Foundation
import Observation

@MainActor
@Observable
public final class HomeViewModel {
    public private(set) var state: Loadable<HomeViewData> = .idle

    private let repository: ServiceStatusRepository
    private(set) var loadTask: Task<Void, Never>?

    public init(repository: ServiceStatusRepository) {
        self.repository = repository
    }

    public func load() {
        loadTask?.cancel()
        state = .loading

        loadTask = Task {
            do {
                let fetched = try await repository.fetchStatus()
                try Task.checkCancellation()
                state = .loaded(Self.viewData(for: fetched))
            } catch is CancellationError {
            } catch {
                Log.report(error, context: Log.Context(operation: "home.load"), logger: Log.network)
                state = .failed(AppError(wrapping: error))
            }
        }
    }

    static func viewData(for status: ServiceStatus) -> HomeViewData {
        switch status {
        case .healthy:
            HomeViewData(statusMessage: String(localized: "home.status.healthy", bundle: .module))
        case .degraded:
            HomeViewData(statusMessage: String(localized: "home.status.degraded", bundle: .module))
        }
    }
}
