import Foundation

@MainActor
public final class AppContainer {
    private let client: any APIClient

    public init(client: (any APIClient)? = nil) {
        self.client = client ?? URLSessionAPIClient(baseURL: Self.apiBaseURL)
    }

    public func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(repository: ServerServiceStatusRepository(client: client))
    }

    private static var apiBaseURL: URL {
        let configured = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String
        guard let configured, let url = URL(string: configured), url.host()?.isEmpty == false else {
            Log.network.error("APIBaseURL is missing or unusable; requests will fail")
            // A compile-time constant that provably parses; every request against
            // it fails and surfaces as AppError.network, which is the intent.
            return URL(string: "http://localhost")!
        }
        return url
    }
}
