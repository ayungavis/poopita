import Foundation

public enum AppError: Error, Equatable, Sendable {
    case network
    case sessionExpired
    case serverRejected
    case badRequest
    case notFound
    case conflict
    case rateLimited(retryAfter: Duration)
    case unavailable
    case unexpected

    public var userMessage: String {
        switch self {
        case .network:
            String(localized: "error.network", bundle: .module)
        case .sessionExpired:
            String(localized: "error.sessionExpired", bundle: .module)
        case .serverRejected:
            String(localized: "error.serverRejected", bundle: .module)
        case .badRequest:
            String(localized: "error.badRequest", bundle: .module)
        case .notFound:
            String(localized: "error.notFound", bundle: .module)
        case .conflict:
            String(localized: "error.conflict", bundle: .module)
        case .rateLimited:
            String(localized: "error.rateLimited", bundle: .module)
        case .unavailable:
            String(localized: "error.unavailable", bundle: .module)
        case .unexpected:
            String(localized: "error.unexpected", bundle: .module)
        }
    }

    public init(wrapping error: Error) {
        if let appError = error as? AppError {
            self = appError
        } else if error is URLError {
            self = .network
        } else {
            self = .unexpected
        }
    }
}
