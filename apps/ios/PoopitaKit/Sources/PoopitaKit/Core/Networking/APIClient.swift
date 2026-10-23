import Foundation

public protocol APIClient: Sendable {
    func send<Route: Endpoint>(_ endpoint: Route) async throws -> Route.Response
    func send<Route: RequestEndpoint>(_ endpoint: Route) async throws -> Route.Response
}

public struct URLSessionAPIClient: APIClient {
    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func send<Route: Endpoint>(_ endpoint: Route) async throws -> Route.Response {
        try await perform(endpoint, body: nil)
    }

    public func send<Route: RequestEndpoint>(_ endpoint: Route) async throws -> Route.Response {
        try await perform(endpoint, body: JSONEncoder.api.encode(endpoint.request))
    }

    private func perform<Route: Endpoint>(_ endpoint: Route, body: Data?) async throws -> Route.Response {
        let (data, response) = try await transfer(endpoint, body: body)

        guard let http = response as? HTTPURLResponse else { throw AppError.network }
        guard (200 ..< 300).contains(http.statusCode) else {
            let failure = Self.failure(status: http.statusCode, body: data, headers: http)
            Log.trail(failure, context: Log.Context(
                endpoint: endpoint.path,
                requestID: http.value(forHTTPHeaderField: "x-request-id"),
                status: http.statusCode
            ))
            throw failure
        }

        if data.isEmpty, let empty = EmptyResponseDTO() as? Route.Response {
            return empty
        }
        do {
            return try JSONDecoder.api.decode(Route.Response.self, from: data)
        } catch {
            Log.report(error, context: Log.Context(endpoint: endpoint.path), logger: Log.network)
            throw AppError.serverRejected
        }
    }

    private func transfer(_ endpoint: some Endpoint, body: Data?) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: Self.url(base: baseURL, endpoint: endpoint))
        request.httpMethod = endpoint.method.rawValue
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            return try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            let failure = AppError(wrapping: error)
            Log.trail(failure, context: Log.Context(endpoint: endpoint.path))
            throw failure
        }
    }

    static func url(base: URL, endpoint: some Endpoint) -> URL {
        let url = base.appending(path: endpoint.path)
        guard !endpoint.queryItems.isEmpty else { return url }
        return url.appending(queryItems: endpoint.queryItems)
    }

    static func failure(status: Int, body: Data, headers: HTTPURLResponse?) -> AppError {
        let code = (try? JSONDecoder.api.decode(ErrorEnvelopeDTO.self, from: body))?.error.code
        return byCode(code, headers) ?? byStatus(status, headers)
    }

    private static func byCode(_ code: String?, _ headers: HTTPURLResponse?) -> AppError? {
        switch code {
        case "unauthenticated": .sessionExpired
        case "bad_request": .badRequest
        case "not_found": .notFound
        case "conflict": .conflict
        case "too_many_requests": .rateLimited(retryAfter: retryAfter(headers))
        case "unavailable": .unavailable
        default: nil
        }
    }

    private static func byStatus(_ status: Int, _ headers: HTTPURLResponse?) -> AppError {
        switch status {
        case 401: .sessionExpired
        case 400: .badRequest
        case 404: .notFound
        case 409: .conflict
        case 429: .rateLimited(retryAfter: retryAfter(headers))
        case 503: .unavailable
        default: .serverRejected
        }
    }

    static func retryAfter(_ headers: HTTPURLResponse?) -> Duration {
        let value = headers?.value(forHTTPHeaderField: "Retry-After")
        return .seconds(value.flatMap(Int.init) ?? 1)
    }
}
