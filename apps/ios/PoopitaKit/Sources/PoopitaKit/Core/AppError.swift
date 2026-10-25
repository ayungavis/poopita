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
    case storageUnavailable
    case storageRead
    case storageWrite
    case invalidStoredData
    case invalidOccurrence
    case invalidObservation
    case noteTooLong
    case nothingToUndo
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
        case .storageUnavailable:
            String(localized: "error.storageUnavailable", bundle: .module)
        case .storageRead:
            String(localized: "error.storageRead", bundle: .module)
        case .storageWrite:
            String(localized: "error.storageWrite", bundle: .module)
        case .invalidStoredData:
            String(localized: "error.invalidStoredData", bundle: .module)
        case .invalidOccurrence:
            String(localized: "error.invalidOccurrence", bundle: .module)
        case .invalidObservation:
            String(localized: "error.invalidObservation", bundle: .module)
        case .noteTooLong:
            String(localized: "error.noteTooLong", bundle: .module)
        case .nothingToUndo:
            String(localized: "error.nothingToUndo", bundle: .module)
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

extension AppError {
    var diagnosticCode: String {
        switch self {
        case .network: "network"
        case .sessionExpired: "sessionExpired"
        case .serverRejected: "serverRejected"
        case .badRequest: "badRequest"
        case .notFound: "notFound"
        case .conflict: "conflict"
        case .rateLimited: "rateLimited"
        case .unavailable: "unavailable"
        case .unexpected: "unexpected"
        case .storageUnavailable: "storageUnavailable"
        case .storageRead: "storageRead"
        case .storageWrite: "storageWrite"
        case .invalidStoredData: "invalidStoredData"
        case .invalidOccurrence: "invalidOccurrence"
        case .invalidObservation: "invalidObservation"
        case .noteTooLong: "noteTooLong"
        case .nothingToUndo: "nothingToUndo"
        }
    }
}
