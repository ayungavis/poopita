public protocol ServiceStatusRepository: Sendable {
    func fetchStatus() async throws -> ServiceStatus
}

public struct ServerServiceStatusRepository: ServiceStatusRepository {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func fetchStatus() async throws -> ServiceStatus {
        let response = try await client.send(GetHealthEndpoint())
        return response.status == "ok" ? .healthy : .degraded
    }
}
