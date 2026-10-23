import Foundation
@testable import PoopitaKit
import Testing

actor ControlledStatusRepository: ServiceStatusRepository {
    private var waiting: [CheckedContinuation<ServiceStatus, Error>] = []
    private var pending: [Result<ServiceStatus, Error>] = []
    private(set) var fetches = 0

    func fetchStatus() async throws -> ServiceStatus {
        fetches += 1
        if !pending.isEmpty {
            return try pending.removeFirst().get()
        }
        return try await withCheckedThrowingContinuation { waiting.append($0) }
    }

    func resolveNext(with result: Result<ServiceStatus, Error>) {
        if waiting.isEmpty {
            pending.append(result)
        } else {
            waiting.removeFirst().resume(with: result)
        }
    }
}

@MainActor
struct HomeViewModelTests {
    @Test func loadSuccessSetsLoadedStatus() async {
        let repository = ControlledStatusRepository()
        let viewModel = HomeViewModel(repository: repository)

        viewModel.load()
        #expect(viewModel.state == .loading)
        await repository.resolveNext(with: .success(.healthy))
        await viewModel.loadTask?.value

        #expect(viewModel.state == .loaded(HomeViewModel.viewData(for: .healthy)))
    }

    @Test func eachStatusMapsToItsOwnLocalizedMessage() {
        let healthy = HomeViewModel.viewData(for: .healthy)
        let degraded = HomeViewModel.viewData(for: .degraded)

        #expect(healthy.statusMessage == String(localized: "home.status.healthy", bundle: .module))
        #expect(degraded.statusMessage == String(localized: "home.status.degraded", bundle: .module))
        #expect(healthy != degraded)
    }

    @Test func loadFailureMapsToAppError() async {
        let repository = ControlledStatusRepository()
        let viewModel = HomeViewModel(repository: repository)

        viewModel.load()
        await repository.resolveNext(with: .failure(URLError(.notConnectedToInternet)))
        await viewModel.loadTask?.value

        #expect(viewModel.state == .failed(.network))
    }

    @Test func aStaleLoadNeverOverwritesTheNewerOne() async {
        let repository = ControlledStatusRepository()
        let viewModel = HomeViewModel(repository: repository)

        viewModel.load()
        let stale = viewModel.loadTask
        while await repository.fetches < 1 {
            await Task.yield()
        }
        viewModel.load()
        let fresh = viewModel.loadTask
        while await repository.fetches < 2 {
            await Task.yield()
        }

        await repository.resolveNext(with: .success(.degraded))
        await stale?.value
        #expect(viewModel.state == .loading)

        await repository.resolveNext(with: .success(.healthy))
        await fresh?.value
        #expect(viewModel.state == .loaded(HomeViewModel.viewData(for: .healthy)))
    }
}
