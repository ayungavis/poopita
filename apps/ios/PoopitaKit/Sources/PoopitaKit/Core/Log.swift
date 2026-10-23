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

    // The app assigns these hooks once at startup before the first report.
    public nonisolated(unsafe) static var errorReporter: (@Sendable (Error, Context) -> Void)?
    public nonisolated(unsafe) static var breadcrumbRecorder: (@Sendable (Error, Context) -> Void)?

    public static func trail(_ error: Error, context: Context, logger: Logger = Log.network) {
        logger.error("\(String(describing: error), privacy: .public) \(context.summary, privacy: .public)")
        breadcrumbRecorder?(error, context)
    }

    public static func report(
        _ error: Error,
        context: Context = Context(),
        logger: Logger = Log.app
    ) {
        logger.error("\(String(describing: error), privacy: .public) \(context.summary, privacy: .public)")
        errorReporter?(error, context)
    }
}
