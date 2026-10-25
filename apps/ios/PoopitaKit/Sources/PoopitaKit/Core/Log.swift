import Foundation
import os

public enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.ayungavis.Poopita"

    public static let app = Logger(subsystem: subsystem, category: "app")
    public static let network = Logger(subsystem: subsystem, category: "network")
    public static let ui = Logger(subsystem: subsystem, category: "ui")

    public struct Context: Sendable, Equatable {
        public var operation: String?
        public var endpoint: String?
        public var requestID: String?
        public var status: Int?

        public init(
            operation: String? = nil,
            endpoint: String? = nil,
            requestID: String? = nil,
            status: Int? = nil
        ) {
            self.operation = operation
            self.endpoint = endpoint
            self.requestID = requestID
            self.status = status
        }

        public var isEmpty: Bool {
            self == Context()
        }

        public var fields: [String: String] {
            [
                "operation": operation,
                "endpoint": endpoint,
                "request_id": requestID,
                "status": status.map(String.init),
            ]
            .compactMapValues(\.self)
        }

        public var summary: String {
            fields.sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
        }
    }

    public struct Diagnostic: Equatable, Sendable {
        public let code: String
        public let fields: [String: String]
    }

    static let diagnosticCodes: Set<String> = [
        "network", "sessionExpired", "serverRejected", "badRequest", "notFound", "conflict",
        "rateLimited", "unavailable", "unexpected", "storageUnavailable", "storageRead", "storageWrite",
        "invalidStoredData", "invalidOccurrence", "invalidObservation", "noteTooLong", "nothingToUndo", "invalidCheckIn",
        "checkInConflict",
    ]
    static let diagnosticOperations: Set<String> = [
        "home.load",
        "diary.load",
        "diary.save",
        "diary.delete",
        "diary.undo",
        "diary.checkIn",
    ]

    public static func diagnostic(_ error: Error, context: Context) -> Diagnostic {
        var fields: [String: String] = [:]
        if let operation = context.operation, diagnosticOperations.contains(operation) {
            fields["operation"] = operation
        }
        if let status = context.status, (100 ... 599).contains(status) {
            fields["status"] = String(status)
        }
        return Diagnostic(code: AppError(wrapping: error).diagnosticCode, fields: fields)
    }

    /// Assigned once at startup before reporting begins.
    public nonisolated(unsafe) static var errorReporter: (@Sendable (Diagnostic) -> Void)?
    /// Assigned once at startup before reporting begins.
    public nonisolated(unsafe) static var breadcrumbRecorder: (@Sendable (Diagnostic) -> Void)?

    public static func trail(_ error: Error, context: Context, logger: Logger = Log.network) {
        let safe = diagnostic(error, context: context)
        write(safe, logger: logger)
        breadcrumbRecorder?(safe)
    }

    public static func report(
        _ error: Error,
        context: Context = Context(),
        logger: Logger = Log.app
    ) {
        let safe = diagnostic(error, context: context)
        write(safe, logger: logger)
        errorReporter?(safe)
    }

    private static func write(_ diagnostic: Diagnostic, logger: Logger) {
        let operation = diagnostic.fields["operation", default: "none"]
        let status = diagnostic.fields["status", default: "none"]
        logger.error("""
        Failure code=\(diagnostic.code, privacy: .public) \
        operation=\(operation, privacy: .public) status=\(status, privacy: .public)
        """)
    }
}
